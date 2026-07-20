package main

import (
	"encoding/json"
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"net/netip"
	"strings"
	"testing"
	"time"

	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/adapter/outbound"
	C "github.com/metacubex/mihomo/constant"
	P "github.com/metacubex/mihomo/constant/provider"
	"github.com/metacubex/mihomo/tunnel"
)

type fakePacketConn struct {
	readData []byte
	readErr  error
	writeN   int
	writeErr error
}

func (c *fakePacketConn) ReadFrom(p []byte) (int, net.Addr, error) {
	if len(c.readData) > 0 {
		n := copy(p, c.readData)
		return n, &net.UDPAddr{IP: net.IPv4(192, 0, 2, 1), Port: 443}, c.readErr
	}
	return 0, nil, c.readErr
}

func (c *fakePacketConn) WriteTo(p []byte, _ net.Addr) (int, error) {
	n := c.writeN
	if n < 0 {
		n = len(p)
	}
	return n, c.writeErr
}

func (c *fakePacketConn) Close() error                       { return nil }
func (c *fakePacketConn) LocalAddr() net.Addr                { return &net.UDPAddr{} }
func (c *fakePacketConn) SetDeadline(_ time.Time) error      { return nil }
func (c *fakePacketConn) SetReadDeadline(_ time.Time) error  { return nil }
func (c *fakePacketConn) SetWriteDeadline(_ time.Time) error { return nil }

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
	if result.Stage != "target_parse" {
		t.Fatalf("expected target_parse stage, got %q", result.Stage)
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
	if result.Stage != "proxy_lookup" {
		t.Fatalf("expected proxy_lookup stage, got %q", result.Stage)
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
	if result.Stage != "udp_capability" {
		t.Fatalf("expected udp_capability stage, got %q", result.Stage)
	}
}

func TestHandleQuicTestProxyWithoutUDP(t *testing.T) {
	t.Cleanup(func() {
		tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})
	})
	tunnel.UpdateProxies(
		map[string]C.Proxy{
			"TCP_ONLY": adapter.NewProxy(outbound.NewBase(outbound.BaseOption{
				Name: "TCP_ONLY",
				Type: C.Ssh,
				UDP:  false,
			})),
		},
		map[string]P.ProxyProvider{},
	)

	ch := make(chan string, 1)
	handleQuicTest(`{"proxy-name":"TCP_ONLY","timeout":100}`, func(value string) { ch <- value })

	var result QuicTestResult
	if err := json.Unmarshal([]byte(waitTestResult(t, ch)), &result); err != nil {
		t.Fatalf("result is not valid json: %v", err)
	}
	if !strings.Contains(result.Error, "does not support udp") {
		t.Fatalf("expected UDP capability error, got %q", result.Error)
	}
	if result.Stage != "udp_capability" {
		t.Fatalf("expected udp_capability stage, got %q", result.Stage)
	}
}

func TestHandleUnlockTestInvalidParams(t *testing.T) {
	ch := make(chan string, 1)
	handleUnlockTest("not-a-json", func(value string) { ch <- value })

	var result UnlockTestResult
	if err := json.Unmarshal([]byte(waitTestResult(t, ch)), &result); err != nil {
		t.Fatalf("result is not valid json: %v", err)
	}
	if !strings.Contains(result.Error, "invalid params") {
		t.Fatalf("expected invalid params error, got %q", result.Error)
	}
}

func TestHandleUnlockTestNoTargets(t *testing.T) {
	ch := make(chan string, 1)
	handleUnlockTest(`{"proxy-name":"DIRECT"}`, func(value string) { ch <- value })

	var result UnlockTestResult
	if err := json.Unmarshal([]byte(waitTestResult(t, ch)), &result); err != nil {
		t.Fatalf("result is not valid json: %v", err)
	}
	if !strings.Contains(result.Error, "no unlock test targets") {
		t.Fatalf("expected no targets error, got %q", result.Error)
	}
}

func TestHandleUnlockTestProxyNotFound(t *testing.T) {
	t.Cleanup(func() {
		tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})
	})
	tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})

	ch := make(chan string, 1)
	handleUnlockTest(
		`{"proxy-name":"nonexistent-unlock-proxy","tests":[{"id":"a","url":"http://127.0.0.1/"}]}`,
		func(value string) { ch <- value },
	)

	var result UnlockTestResult
	if err := json.Unmarshal([]byte(waitTestResult(t, ch)), &result); err != nil {
		t.Fatalf("result is not valid json: %v", err)
	}
	if result.Name != "nonexistent-unlock-proxy" {
		t.Fatalf("expected name to echo proxy-name, got %q", result.Name)
	}
	if !strings.Contains(result.Error, "not found") {
		t.Fatalf("expected not found error, got %q", result.Error)
	}
}

func TestHandleUnlockTestRejectProxy(t *testing.T) {
	t.Cleanup(func() {
		tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})
	})
	tunnel.UpdateProxies(
		map[string]C.Proxy{"REJECT": adapter.NewProxy(outbound.NewReject())},
		map[string]P.ProxyProvider{},
	)

	ch := make(chan string, 1)
	handleUnlockTest(
		`{"proxy-name":"REJECT","timeout":100,"tests":[{"id":"a","url":"http://127.0.0.1/"}]}`,
		func(value string) { ch <- value },
	)

	var result UnlockTestResult
	if err := json.Unmarshal([]byte(waitTestResult(t, ch)), &result); err != nil {
		t.Fatalf("result is not valid json: %v", err)
	}
	if result.Error == "" {
		t.Fatal("expected error for REJECT proxy, got empty error")
	}
}

func TestHandleUnlockTestDirect(t *testing.T) {
	t.Cleanup(func() {
		tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})
	})
	tunnel.UpdateProxies(
		map[string]C.Proxy{"DIRECT": adapter.NewProxy(outbound.NewDirect())},
		map[string]P.ProxyProvider{},
	)

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/trace":
			_, _ = w.Write([]byte("fl=1\nloc=US\n"))
		case "/blocked":
			w.WriteHeader(http.StatusForbidden)
		case "/redirect":
			w.Header().Set("Location", "/trace")
			w.WriteHeader(http.StatusFound)
		}
	}))
	t.Cleanup(server.Close)

	params, err := json.Marshal(UnlockTestParams{
		ProxyName: "DIRECT",
		Timeout:   2000,
		Tests: []UnlockTestItem{
			{Id: "trace", Url: server.URL + "/trace", RegionRegex: "loc=([A-Z]{2})"},
			{Id: "blocked", Url: server.URL + "/blocked"},
			{Id: "redirect", Url: server.URL + "/redirect", ExpectedStatus: []int{http.StatusFound}},
			{Id: "bad-regex", Url: server.URL + "/trace", RegionRegex: "loc=("},
			{Id: "empty-url"},
		},
	})
	if err != nil {
		t.Fatalf("marshal params: %v", err)
	}

	ch := make(chan string, 1)
	handleUnlockTest(string(params), func(value string) { ch <- value })

	var result UnlockTestResult
	if err := json.Unmarshal([]byte(waitTestResult(t, ch)), &result); err != nil {
		t.Fatalf("result is not valid json: %v", err)
	}
	if result.Error != "" {
		t.Fatalf("unexpected top-level error: %q", result.Error)
	}
	if len(result.Results) != 5 {
		t.Fatalf("expected 5 results, got %d", len(result.Results))
	}
	items := make(map[string]UnlockTestResultItem, len(result.Results))
	for _, item := range result.Results {
		items[item.Id] = item
	}

	trace := items["trace"]
	if !trace.Unlocked || trace.Status != http.StatusOK || trace.Region != "US" {
		t.Fatalf("trace result = %+v, want unlocked 200 US", trace)
	}
	blocked := items["blocked"]
	if blocked.Unlocked || blocked.Status != http.StatusForbidden {
		t.Fatalf("blocked result = %+v, want locked 403", blocked)
	}
	redirect := items["redirect"]
	if !redirect.Unlocked || redirect.Status != http.StatusFound {
		t.Fatalf("redirect result = %+v, want unlocked 302", redirect)
	}
	if badRegex := items["bad-regex"]; !strings.Contains(badRegex.Error, "invalid region regex") {
		t.Fatalf("bad-regex result = %+v, want regex error", badRegex)
	}
	if emptyUrl := items["empty-url"]; emptyUrl.Error == "" {
		t.Fatalf("empty-url result = %+v, want error", emptyUrl)
	}
}

func TestNormalizeQuicTarget(t *testing.T) {	tests := []struct {
		name       string
		input      string
		wantTarget string
		wantServer string
	}{
		{
			name:       "empty uses default",
			wantTarget: "cloudflare-quic.com:443",
			wantServer: "cloudflare-quic.com",
		},
		{
			name:       "domain adds default port",
			input:      "cloudflare-quic.com",
			wantTarget: "cloudflare-quic.com:443",
			wantServer: "cloudflare-quic.com",
		},
		{
			name:       "domain preserves port",
			input:      "cloudflare-quic.com:8443",
			wantTarget: "cloudflare-quic.com:8443",
			wantServer: "cloudflare-quic.com",
		},
		{
			name:       "IPv4 adds default port",
			input:      "192.0.2.1",
			wantTarget: "192.0.2.1:443",
			wantServer: "192.0.2.1",
		},
		{
			name:       "bare IPv6 adds default port",
			input:      "2001:db8::1",
			wantTarget: "[2001:db8::1]:443",
			wantServer: "2001:db8::1",
		},
		{
			name:       "IPv6 preserves port",
			input:      "[2001:db8::1]:8443",
			wantTarget: "[2001:db8::1]:8443",
			wantServer: "2001:db8::1",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			target, serverName, err := normalizeQuicTarget(tt.input)
			if err != nil {
				t.Fatalf("normalizeQuicTarget() error = %v", err)
			}
			if target != tt.wantTarget {
				t.Fatalf("target = %q, want %q", target, tt.wantTarget)
			}
			if serverName != tt.wantServer {
				t.Fatalf("serverName = %q, want %q", serverName, tt.wantServer)
			}
		})
	}
}

func TestNormalizeQuicTargetRejectsInvalidInput(t *testing.T) {
	for _, input := range []string{
		"cloudflare-quic.com:0",
		"cloudflare-quic.com:70000",
		"cloudflare-quic.com:not-a-port",
		"https://cloudflare-quic.com",
		"cloudflare-quic.com:443:extra",
		"[2001:db8::1",
		"bad target",
	} {
		t.Run(input, func(t *testing.T) {
			if _, _, err := normalizeQuicTarget(input); err == nil {
				t.Fatalf("normalizeQuicTarget(%q) expected an error", input)
			}
		})
	}
}

func TestResolvedQuicUDPAddrUsesMetadataAddress(t *testing.T) {
	metadata := &C.Metadata{NetWork: C.UDP}
	if err := metadata.SetRemoteAddress("dns.invalid:443"); err != nil {
		t.Fatalf("SetRemoteAddress() error = %v", err)
	}
	metadata.DstIP = netip.MustParseAddr("203.0.113.7")

	addr, network, err := resolvedQuicUDPAddr(metadata)
	if err != nil {
		t.Fatalf("resolvedQuicUDPAddr() error = %v", err)
	}
	if got := addr.String(); got != "203.0.113.7:443" {
		t.Fatalf("resolved address = %q, want %q", got, "203.0.113.7:443")
	}
	if network != "udp4" {
		t.Fatalf("network = %q, want udp4", network)
	}
}

func TestResolvedQuicUDPAddrRequiresProxyResolution(t *testing.T) {
	metadata := &C.Metadata{NetWork: C.UDP}
	if err := metadata.SetRemoteAddress("dns.invalid:443"); err != nil {
		t.Fatalf("SetRemoteAddress() error = %v", err)
	}

	if _, _, err := resolvedQuicUDPAddr(metadata); err == nil {
		t.Fatal("expected unresolved metadata error")
	}
}

func TestQuicPacketConnStatistics(t *testing.T) {
	fake := &fakePacketConn{
		readData: []byte("response"),
		writeN:   -1,
	}
	packetConn := outbound.NewPacketConn(fake, outbound.NewDirect())
	conn := &quicPacketConn{PacketConn: packetConn}
	t.Cleanup(func() { _ = conn.Close() })

	payload := []byte("request")
	if n, err := conn.WriteTo(payload, &net.UDPAddr{}); err != nil || n != len(payload) {
		t.Fatalf("WriteTo() = (%d, %v), want (%d, nil)", n, err, len(payload))
	}
	buffer := make([]byte, 32)
	if n, _, err := conn.ReadFrom(buffer); err != nil || n != len(fake.readData) {
		t.Fatalf("ReadFrom() = (%d, %v), want (%d, nil)", n, err, len(fake.readData))
	}

	result := &QuicTestResult{}
	conn.updateResult(result)
	if result.SentPackets != 1 || result.SentBytes != int64(len(payload)) {
		t.Fatalf("sent stats = (%d, %d), want (1, %d)", result.SentPackets, result.SentBytes, len(payload))
	}
	if result.ReceivedPackets != 1 || result.ReceivedBytes != int64(len(fake.readData)) {
		t.Fatalf(
			"received stats = (%d, %d), want (1, %d)",
			result.ReceivedPackets,
			result.ReceivedBytes,
			len(fake.readData),
		)
	}
}

func TestQuicPacketConnDoesNotCountFailedIO(t *testing.T) {
	fake := &fakePacketConn{
		readErr:  errors.New("read failed"),
		writeErr: errors.New("write failed"),
	}
	packetConn := outbound.NewPacketConn(fake, outbound.NewDirect())
	conn := &quicPacketConn{PacketConn: packetConn}
	t.Cleanup(func() { _ = conn.Close() })

	if n, err := conn.WriteTo([]byte("request"), &net.UDPAddr{}); n != 0 || err == nil {
		t.Fatalf("WriteTo() = (%d, %v), want (0, error)", n, err)
	}
	if n, _, err := conn.ReadFrom(make([]byte, 32)); n != 0 || err == nil {
		t.Fatalf("ReadFrom() = (%d, %v), want (0, error)", n, err)
	}

	result := &QuicTestResult{}
	conn.updateResult(result)
	if result.SentPackets != 0 || result.SentBytes != 0 ||
		result.ReceivedPackets != 0 || result.ReceivedBytes != 0 {
		t.Fatalf("failed I/O changed stats: %+v", result)
	}
}
