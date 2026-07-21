package unlocktest

import (
	"context"
	"errors"
	"sync/atomic"
	"testing"
	"time"
)

func TestRunnerLimitsConcurrencyAndStreamsProgress(t *testing.T) {
	var active atomic.Int32
	var maximum atomic.Int32
	release := make(chan struct{})
	started := make(chan struct{}, 4)

	probe := ProbeFunc(func(ctx context.Context, client *Client) Outcome {
		current := active.Add(1)
		defer active.Add(-1)
		for {
			previous := maximum.Load()
			if current <= previous || maximum.CompareAndSwap(previous, current) {
				break
			}
		}
		started <- struct{}{}
		select {
		case <-release:
			return Outcome{Status: StatusUnlocked}
		case <-ctx.Done():
			return Outcome{Status: StatusError, Reason: ReasonTimeout}
		}
	})

	registry := map[string]Target{
		"a": {ID: "a", Group: GroupAI, Probe: probe},
		"b": {ID: "b", Group: GroupAI, Probe: probe},
		"c": {ID: "c", Group: GroupAI, Probe: probe},
		"d": {ID: "d", Group: GroupAI, Probe: probe},
	}
	runner := Runner{Registry: registry, Concurrency: 2}
	progress := make(chan Progress, 4)
	done := make(chan Result, 1)
	go func() {
		done <- runner.Run(
			context.Background(),
			Request{
				RunID:     "run-1",
				RouteMode: RouteModeAppRoute,
				TargetIDs: []string{"a", "b", "c", "d"},
				Timeout:   time.Second,
			},
			nil,
			func(value Progress) { progress <- value },
		)
	}()

	<-started
	<-started
	select {
	case <-started:
		t.Fatal("third probe started before a concurrency slot was released")
	case <-time.After(30 * time.Millisecond):
	}
	close(release)

	result := <-done
	if maximum.Load() != 2 {
		t.Fatalf("maximum concurrency = %d, want 2", maximum.Load())
	}
	if len(result.Results) != 4 {
		t.Fatalf("result count = %d, want 4", len(result.Results))
	}
	for index, id := range []string{"a", "b", "c", "d"} {
		if result.Results[index].ID != id {
			t.Fatalf("result[%d].id = %q, want %q", index, result.Results[index].ID, id)
		}
	}
	for completed := 1; completed <= 4; completed++ {
		event := <-progress
		if event.RunID != "run-1" || event.Completed != completed || event.Total != 4 {
			t.Fatalf("unexpected progress event: %#v", event)
		}
	}
}

func TestRunnerCancellationDoesNotReportACompletedRun(t *testing.T) {
	started := make(chan struct{})
	probe := ProbeFunc(func(ctx context.Context, client *Client) Outcome {
		close(started)
		<-ctx.Done()
		return Outcome{Status: StatusError, Reason: ReasonNetworkError}
	})
	runner := Runner{
		Registry: map[string]Target{
			"slow": {ID: "slow", Group: GroupAI, Probe: probe},
		},
	}
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan Result, 1)
	go func() {
		done <- runner.Run(
			ctx,
			Request{
				RunID:     "cancelled",
				RouteMode: RouteModeAppRoute,
				TargetIDs: []string{"slow"},
				Timeout:   time.Second,
			},
			nil,
			nil,
		)
	}()
	<-started
	cancel()

	result := <-done
	if !result.Cancelled {
		t.Fatalf("cancelled = false, want true: %#v", result)
	}
}

func TestClassifyErrorDoesNotLeakRequestDetails(t *testing.T) {
	item := itemFromError("service", errors.New(
		`Get "https://example.com/bootstrap?token=secret": context deadline exceeded`,
	), 20*time.Millisecond, nil)

	if item.Status != StatusError || item.Reason != ReasonTimeout {
		t.Fatalf("unexpected item: %#v", item)
	}
	if item.SanitizedDetail != "request timed out" {
		t.Fatalf("detail leaked transport data: %q", item.SanitizedDetail)
	}
}

func TestRunnerRejectsInvalidRunMetadata(t *testing.T) {
	for _, testCase := range []struct {
		name    string
		request Request
	}{
		{
			name: "missing run id",
			request: Request{
				RouteMode: RouteModeAppRoute,
				TargetIDs: []string{"chatgpt"},
			},
		},
		{
			name: "proxy mode without proxy",
			request: Request{
				RunID:     "run-proxy",
				RouteMode: RouteModeProxy,
				TargetIDs: []string{"chatgpt"},
			},
		},
		{
			name: "unknown route mode",
			request: Request{
				RunID:     "run-route",
				RouteMode: RouteMode("unknown"),
				TargetIDs: []string{"chatgpt"},
			},
		},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			called := false
			runner := Runner{
				Registry: map[string]Target{
					"chatgpt": {
						ID:    "chatgpt",
						Group: GroupAI,
						Probe: ProbeFunc(func(context.Context, *Client) Outcome {
							called = true
							return Outcome{Status: StatusUnlocked}
						}),
					},
				},
			}
			result := runner.Run(
				context.Background(),
				testCase.request,
				nil,
				nil,
			)
			if result.Error == "" {
				t.Fatalf("invalid request was accepted: %#v", result)
			}
			if len(result.Results) != 0 {
				t.Fatalf("invalid request produced item results: %#v", result)
			}
			if called {
				t.Fatal("invalid request reached a service probe")
			}
		})
	}
}
