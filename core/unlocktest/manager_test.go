package unlocktest

import (
	"context"
	"testing"
	"time"
)

func TestManagerCancelsARunningProbeByRunID(t *testing.T) {
	started := make(chan struct{})
	probe := ProbeFunc(func(ctx context.Context, client *Client) Outcome {
		close(started)
		<-ctx.Done()
		return Outcome{Status: StatusError, Reason: ReasonNetworkError}
	})
	manager := NewManager(Runner{
		Registry: map[string]Target{
			"slow": {ID: "slow", Group: GroupAI, Probe: probe},
		},
	})
	done := make(chan Result, 1)
	go func() {
		done <- manager.Run(
			context.Background(),
			Request{
				RunID:     "managed-run",
				RouteMode: RouteModeAppRoute,
				TargetIDs: []string{"slow"},
				Timeout:   time.Second,
			},
			nil,
			nil,
		)
	}()
	<-started

	if !manager.Cancel("managed-run") {
		t.Fatal("Cancel returned false for a running test")
	}
	result := <-done
	if !result.Cancelled {
		t.Fatalf("cancelled = false, want true: %#v", result)
	}
	if manager.Cancel("managed-run") {
		t.Fatal("completed run remained registered")
	}
}

func TestManagerRejectsDuplicateRunIDByCancellingTheOlderRun(t *testing.T) {
	started := make(chan struct{}, 2)
	probe := ProbeFunc(func(ctx context.Context, client *Client) Outcome {
		started <- struct{}{}
		<-ctx.Done()
		return Outcome{Status: StatusError, Reason: ReasonNetworkError}
	})
	manager := NewManager(Runner{
		Registry: map[string]Target{
			"slow": {ID: "slow", Group: GroupAI, Probe: probe},
		},
	})
	first := make(chan Result, 1)
	go func() {
		first <- manager.Run(
			context.Background(),
			Request{
				RunID:     "same-id",
				RouteMode: RouteModeAppRoute,
				TargetIDs: []string{"slow"},
			},
			nil,
			nil,
		)
	}()
	<-started

	second := make(chan Result, 1)
	go func() {
		second <- manager.Run(
			context.Background(),
			Request{
				RunID:     "same-id",
				RouteMode: RouteModeAppRoute,
				TargetIDs: []string{"slow"},
			},
			nil,
			nil,
		)
	}()
	if result := <-first; !result.Cancelled {
		t.Fatalf("older duplicate run was not cancelled: %#v", result)
	}
	<-started
	manager.Cancel("same-id")
	<-second
}
