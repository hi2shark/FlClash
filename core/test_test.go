package main

import (
	"encoding/json"
	"strings"
	"testing"
	"time"

	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/adapter/outbound"
	C "github.com/metacubex/mihomo/constant"
	P "github.com/metacubex/mihomo/constant/provider"
	"github.com/metacubex/mihomo/tunnel"
)

func waitTestResult(t *testing.T, ch chan string) string {
	t.Helper()
	select {
	case value := <-ch:
		return value
	case <-time.After(5 * time.Second):
		t.Fatal("timed out waiting for test result")
		return ""
	}
}

func TestHandleSpeedTestInvalidParams(t *testing.T) {
	ch := make(chan string, 1)
	handleSpeedTest("not-a-json", func(value string) { ch <- value })

	var result SpeedTestResult
	if err := json.Unmarshal([]byte(waitTestResult(t, ch)), &result); err != nil {
		t.Fatalf("result is not valid json: %v", err)
	}
	if !strings.Contains(result.Error, "invalid params") {
		t.Fatalf("expected invalid params error, got %q", result.Error)
	}
}

func TestHandleSpeedTestProxyNotFound(t *testing.T) {
	t.Cleanup(func() {
		tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})
	})
	tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})

	ch := make(chan string, 1)
	handleSpeedTest(`{"proxy-name":"nonexistent-speed-proxy"}`, func(value string) { ch <- value })

	var result SpeedTestResult
	if err := json.Unmarshal([]byte(waitTestResult(t, ch)), &result); err != nil {
		t.Fatalf("result is not valid json: %v", err)
	}
	if result.Name != "nonexistent-speed-proxy" {
		t.Fatalf("expected name to echo proxy-name, got %q", result.Name)
	}
	if !strings.Contains(result.Error, "not found") {
		t.Fatalf("expected not found error, got %q", result.Error)
	}
}

func TestHandleSpeedTestRejectProxy(t *testing.T) {
	t.Cleanup(func() {
		tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})
	})
	tunnel.UpdateProxies(
		map[string]C.Proxy{"REJECT": adapter.NewProxy(outbound.NewReject())},
		map[string]P.ProxyProvider{},
	)

	ch := make(chan string, 1)
	handleSpeedTest(`{"proxy-name":"REJECT","timeout":100}`, func(value string) { ch <- value })

	var result SpeedTestResult
	if err := json.Unmarshal([]byte(waitTestResult(t, ch)), &result); err != nil {
		t.Fatalf("result is not valid json: %v", err)
	}
	if result.Error == "" {
		t.Fatal("expected error for REJECT proxy, got empty error")
	}
}

func TestHandleQuicTestInvalidParams(t *testing.T) {
	ch := make(chan string, 1)
	handleQuicTest("{", func(value string) { ch <- value })

	var result QuicTestResult
	if err := json.Unmarshal([]byte(waitTestResult(t, ch)), &result); err != nil {
		t.Fatalf("result is not valid json: %v", err)
	}
	if !strings.Contains(result.Error, "invalid params") {
		t.Fatalf("expected invalid params error, got %q", result.Error)
	}
}

func TestHandleQuicTestProxyNotFound(t *testing.T) {
	t.Cleanup(func() {
		tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})
	})
	tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})

	ch := make(chan string, 1)
	handleQuicTest(`{"proxy-name":"nonexistent-quic-proxy"}`, func(value string) { ch <- value })

	var result QuicTestResult
	if err := json.Unmarshal([]byte(waitTestResult(t, ch)), &result); err != nil {
		t.Fatalf("result is not valid json: %v", err)
	}
	if result.Name != "nonexistent-quic-proxy" {
		t.Fatalf("expected name to echo proxy-name, got %q", result.Name)
	}
	if !strings.Contains(result.Error, "not found") {
		t.Fatalf("expected not found error, got %q", result.Error)
	}
}

func TestHandleQuicTestRejectProxy(t *testing.T) {
	t.Cleanup(func() {
		tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})
	})
	tunnel.UpdateProxies(
		map[string]C.Proxy{"REJECT": adapter.NewProxy(outbound.NewReject())},
		map[string]P.ProxyProvider{},
	)

	ch := make(chan string, 1)
	// REJECT reports SupportUDP() == true, so this also guards the nop adapter check
	handleQuicTest(`{"proxy-name":"REJECT","timeout":100}`, func(value string) { ch <- value })

	var result QuicTestResult
	if err := json.Unmarshal([]byte(waitTestResult(t, ch)), &result); err != nil {
		t.Fatalf("result is not valid json: %v", err)
	}
	if result.Error == "" {
		t.Fatal("expected error for REJECT proxy, got empty error")
	}
}
