package unlocktest

import (
	"context"
	"sync"
)

type managedRun struct {
	cancel context.CancelFunc
}

type Manager struct {
	runner Runner
	mu     sync.Mutex
	runs   map[string]*managedRun
}

func NewManager(runner Runner) *Manager {
	return &Manager{
		runner: runner,
		runs:   make(map[string]*managedRun),
	}
}

func (manager *Manager) Run(
	parent context.Context,
	request Request,
	dialer DialContext,
	onProgress func(Progress),
) Result {
	runContext, cancel := context.WithCancel(parent)
	run := &managedRun{cancel: cancel}

	manager.mu.Lock()
	previous := manager.runs[request.RunID]
	manager.runs[request.RunID] = run
	manager.mu.Unlock()
	if previous != nil {
		previous.cancel()
	}

	defer func() {
		cancel()
		manager.mu.Lock()
		if manager.runs[request.RunID] == run {
			delete(manager.runs, request.RunID)
		}
		manager.mu.Unlock()
	}()
	return manager.runner.Run(runContext, request, dialer, onProgress)
}

func (manager *Manager) Cancel(runID string) bool {
	manager.mu.Lock()
	run := manager.runs[runID]
	manager.mu.Unlock()
	if run == nil {
		return false
	}
	run.cancel()
	return true
}
