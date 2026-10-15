package unlocktest

import (
	"context"
	"errors"
	"net"
	"strings"
	"sync"
	"time"
)

const DefaultConcurrency = 4

type Runner struct {
	Registry    map[string]Target
	Concurrency int
}

func (runner Runner) Run(
	ctx context.Context,
	request Request,
	dialer DialContext,
	onProgress func(Progress),
) Result {
	result := Result{
		RunID:     request.RunID,
		RouteMode: request.RouteMode,
		ProxyName: request.ProxyName,
	}
	if strings.TrimSpace(request.RunID) == "" {
		result.Error = "unlock test run id is required"
		return result
	}
	switch request.RouteMode {
	case RouteModeAppRoute:
	case RouteModeProxy:
		if strings.TrimSpace(request.ProxyName) == "" {
			result.Error = "unlock test proxy is required"
			return result
		}
	default:
		result.Error = "invalid unlock test route mode"
		return result
	}
	if len(request.TargetIDs) == 0 {
		result.Error = "no unlock test targets"
		return result
	}
	result.Results = make([]Item, len(request.TargetIDs))

	concurrency := runner.Concurrency
	if concurrency <= 0 {
		concurrency = DefaultConcurrency
	}
	registry := runner.Registry
	if registry == nil {
		registry = Registry()
	}
	specialProxy := ""
	if request.RouteMode == RouteModeProxy {
		specialProxy = request.ProxyName
	}

	semaphore := make(chan struct{}, concurrency)
	var progressMu sync.Mutex
	completed := 0
	var waitGroup sync.WaitGroup
	for index, id := range request.TargetIDs {
		waitGroup.Add(1)
		go func(index int, id string) {
			defer waitGroup.Done()
			select {
			case semaphore <- struct{}{}:
				defer func() { <-semaphore }()
			case <-ctx.Done():
				return
			}

			item := runner.runItem(ctx, registry, id, request.EffectiveTimeout(), dialer, specialProxy)
			result.Results[index] = item
			progressMu.Lock()
			completed++
			if onProgress != nil {
				onProgress(Progress{
					RunID:     request.RunID,
					Completed: completed,
					Total:     len(request.TargetIDs),
					Item:      item,
				})
			}
			progressMu.Unlock()
		}(index, id)
	}
	waitGroup.Wait()
	result.Cancelled = ctx.Err() != nil
	if result.Cancelled {
		result.Results = completedItems(result.Results)
	}
	return result
}

func (runner Runner) runItem(
	ctx context.Context,
	registry map[string]Target,
	id string,
	timeout time.Duration,
	dialer DialContext,
	specialProxy string,
) Item {
	target, ok := registry[id]
	if !ok {
		return Item{
			ID:              id,
			Status:          StatusError,
			Reason:          ReasonUnexpectedResponse,
			SanitizedDetail: "unsupported unlock test target",
		}
	}
	itemContext, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	client := NewClient(dialer, specialProxy)
	defer client.Close()

	startedAt := time.Now()
	outcome := target.Probe.Run(itemContext, client)
	elapsed := time.Since(startedAt)
	if itemContext.Err() != nil && outcome.Status != StatusUnlocked &&
		outcome.Status != StatusPartial && outcome.Status != StatusLocked {
		return itemFromError(id, itemContext.Err(), elapsed, client.OutboundChains())
	}
	if outcome.Status == "" {
		outcome.Status = StatusError
		outcome.Reason = ReasonUnexpectedResponse
		outcome.Detail = "probe returned no status"
	}
	return Item{
		ID:              id,
		Status:          outcome.Status,
		Reason:          outcome.Reason,
		Region:          strings.ToUpper(outcome.Region),
		Latency:         elapsed.Milliseconds(),
		OutboundChains:  client.OutboundChains(),
		SanitizedDetail: outcome.Detail,
	}
}

func itemFromError(id string, err error, elapsed time.Duration, chains []string) Item {
	reason := ReasonNetworkError
	detail := "network request failed"
	var networkError net.Error
	if errors.Is(err, context.DeadlineExceeded) ||
		strings.Contains(strings.ToLower(err.Error()), "deadline exceeded") ||
		(errors.As(err, &networkError) && networkError.Timeout()) {
		reason = ReasonTimeout
		detail = "request timed out"
	}
	return Item{
		ID:              id,
		Status:          StatusError,
		Reason:          reason,
		Latency:         elapsed.Milliseconds(),
		OutboundChains:  chains,
		SanitizedDetail: detail,
	}
}

func completedItems(items []Item) []Item {
	completed := make([]Item, 0, len(items))
	for _, item := range items {
		if item.ID != "" {
			completed = append(completed, item)
		}
	}
	return completed
}
