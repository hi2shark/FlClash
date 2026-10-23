package core

import (
	"context"
	"encoding/json"
	"errors"
	"net"
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
	readAddr net.Addr
	readErr  error
	writeN   int
	writeErr error
}

func (c *fakePacketConn) ReadFrom(p []byte) (int, net.Addr, error) {
	addr := c.readAddr
	if addr == nil {
		addr = &net.UDPAddr{IP: net.IPv4(203, 0, 113, 1), Port: 443}
	}
	if len(c.readData) > 0 {
		n := copy(p, c.readData)
		return n, addr, c.readErr
	}
	return 0, nil, c.readErr
}

type unresolvedUDPAdapter struct {
	*outbound.Base
	pc net.PacketConn
}

func (a *unresolvedUDPAdapter) ListenPacketContext(_ context.Context, _ *C.Metadata) (C.PacketConn, error) {
	return outbound.NewPacketConn(a.pc, a), nil
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

func TestSpeedTestRejectsInvalidParams(t *testing.T) {
	frame := handleMethodCall(&MethodCall{Method: speedTestMethod, Arguments: json.RawMessage("not-a-json")})

	var envelope struct {
		Error *MethodError `json:"error"`
	}
	if err := json.Unmarshal(frame, &envelope); err != nil {
		t.Fatalf("response is not valid JSON: %v", err)
	}
	if envelope.Error == nil || envelope.Error.Code != "invalid_arguments" {
		t.Fatalf("error = %+v, want code invalid_arguments", envelope.Error)
	}
}

func TestQuicTestRejectsInvalidParams(t *testing.T) {
	frame := handleMethodCall(&MethodCall{Method: quicTestMethod, Arguments: json.RawMessage("{")})

	var envelope struct {
		Error *MethodError `json:"error"`
	}
	if err := json.Unmarshal(frame, &envelope); err != nil {
		t.Fatalf("response is not valid JSON: %v", err)
	}
	if envelope.Error == nil || envelope.Error.Code != "invalid_arguments" {
		t.Fatalf("error = %+v, want code invalid_arguments", envelope.Error)
	}
}

func TestHandleSpeedTestProxyNotFound(t *testing.T) {
	t.Cleanup(func() {
		tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})
	})
	tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})

	result := handleSpeedTest(&SpeedTestParams{ProxyName: "nonexistent-speed-proxy"})

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

	result := handleSpeedTest(&SpeedTestParams{ProxyName: "REJECT", Timeout: 100})

	if result.Error == "" {
		t.Fatal("expected error for REJECT proxy, got empty error")
	}
}

func TestHandleQuicTestProxyNotFound(t *testing.T) {
	t.Cleanup(func() {
		tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})
	})
	tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})

	result := handleQuicTest(&QuicTestParams{ProxyName: "nonexistent-quic-proxy"})

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

	// REJECT reports SupportUDP() == true, so this also guards the nop adapter check
	result := handleQuicTest(&QuicTestParams{ProxyName: "REJECT", Timeout: 100})

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

	result := handleQuicTest(&QuicTestParams{ProxyName: "TCP_ONLY", Timeout: 100})

	if !strings.Contains(result.Error, "does not support udp") {
		t.Fatalf("expected UDP capability error, got %q", result.Error)
	}
	if result.Stage != "udp_capability" {
		t.Fatalf("expected udp_capability stage, got %q", result.Stage)
	}
}

func TestNormalizeQuicTarget(t *testing.T) {
	tests := []struct {
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

func TestResolvedQuicUDPAddrPlaceholderWhenUnresolved(t *testing.T) {
	metadata := &C.Metadata{NetWork: C.UDP}
	if err := metadata.SetRemoteAddress("dns.invalid:443"); err != nil {
		t.Fatalf("SetRemoteAddress() error = %v", err)
	}

	addr, network, err := resolvedQuicUDPAddr(metadata)
	if err != nil {
		t.Fatalf("resolvedQuicUDPAddr() error = %v", err)
	}
	if got := addr.String(); got != "192.0.2.1:443" {
		t.Fatalf("resolved address = %q, want placeholder 192.0.2.1:443", got)
	}
	if network != "udp4" {
		t.Fatalf("network = %q, want udp4", network)
	}
	if metadata.Resolved() {
		t.Fatal("placeholder must not mark metadata as resolved")
	}
}

func TestHandleQuicTestUnresolvedUDPRelayContinuesPastResolve(t *testing.T) {
	t.Cleanup(func() {
		tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})
	})
	unresolved := &unresolvedUDPAdapter{
		Base: outbound.NewBase(outbound.BaseOption{
			Name: "UNRESOLVED_UDP",
			Type: C.Direct,
			UDP:  true,
		}),
		pc: &fakePacketConn{
			writeN:  -1,
			readErr: errors.New("no datagram"),
		},
	}
	tunnel.UpdateProxies(
		map[string]C.Proxy{"UNRESOLVED_UDP": adapter.NewProxy(unresolved)},
		map[string]P.ProxyProvider{},
	)

	result := handleQuicTest(&QuicTestParams{
		ProxyName: "UNRESOLVED_UDP",
		Host:      "dns.invalid:443",
		Timeout:   100,
	})

	if result.Stage == "target_resolve" {
		t.Fatalf("unresolved UDP relay should continue past target_resolve, got %+v", result)
	}
	if strings.Contains(result.Error, "target was not resolved by proxy") {
		t.Fatalf("unexpected local-resolve error: %q", result.Error)
	}
	if result.ResolvedIP != "" {
		t.Fatalf("placeholder path must leave resolved-ip empty, got %q", result.ResolvedIP)
	}
	if result.Network != "udp4" {
		t.Fatalf("network = %q, want udp4", result.Network)
	}
}

func TestQuicPacketConnReadFromPinsPeer(t *testing.T) {
	fake := &fakePacketConn{
		readData: []byte("response"),
		readAddr: &net.UDPAddr{IP: net.IPv4(203, 0, 113, 9), Port: 443},
		writeN:   -1,
	}
	peer := &net.UDPAddr{IP: net.IPv4(192, 0, 2, 1), Port: 443}
	packetConn := outbound.NewPacketConn(fake, outbound.NewDirect())
	conn := &quicPacketConn{PacketConn: packetConn, peer: peer}
	t.Cleanup(func() { _ = conn.Close() })

	buffer := make([]byte, 32)
	n, addr, err := conn.ReadFrom(buffer)
	if err != nil || n != len(fake.readData) {
		t.Fatalf("ReadFrom() = (%d, %v), want (%d, nil)", n, err, len(fake.readData))
	}
	if addr == nil || addr.String() != peer.String() {
		t.Fatalf("ReadFrom addr = %v, want pinned peer %s", addr, peer)
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
