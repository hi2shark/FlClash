package main

import (
	"context"
	"core/unlocktest"
	gotls "crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/netip"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"
	"unicode"

	N "github.com/metacubex/mihomo/common/net"
	C "github.com/metacubex/mihomo/constant"
	T "github.com/metacubex/mihomo/tunnel"
	"github.com/metacubex/mihomo/tunnel/statistic"
	quic "github.com/metacubex/quic-go"
	"github.com/metacubex/tls"
)

const (
	defaultSpeedTestUrl     = "https://speed.cloudflare.com/__down?bytes=25000000"
	defaultSpeedTestTimeout = 15 * time.Second
	defaultQuicTestHost     = "cloudflare-quic.com:443"
	defaultQuicTestTimeout  = 8 * time.Second
)

type SpeedTestResult struct {
	Name    string  `json:"name"`
	Latency int64   `json:"latency"` // time to first byte, ms
	Speed   float64 `json:"speed"`   // bytes/sec
	Bytes   int64   `json:"bytes"`
	Error   string  `json:"error"`
}

type QuicTestResult struct {
	Name            string `json:"name"`
	Rtt             int64  `json:"rtt"` // handshake duration, ms
	Alpn            string `json:"alpn"`
	Version         uint32 `json:"version"` // QUIC version number
	Error           string `json:"error"`
	Stage           string `json:"stage"`
	Target          string `json:"target"`
	ResolvedIP      string `json:"resolved-ip"`
	Network         string `json:"network"`
	SentPackets     int64  `json:"sent-packets"`
	SentBytes       int64  `json:"sent-bytes"`
	ReceivedPackets int64  `json:"received-packets"`
	ReceivedBytes   int64  `json:"received-bytes"`
}

// quicPacketConn adapts a mihomo constant.PacketConn to net.PacketConn for quic-go.
type quicPacketConn struct {
	C.PacketConn

	sentPackets     atomic.Int64
	sentBytes       atomic.Int64
	receivedPackets atomic.Int64
	receivedBytes   atomic.Int64
}

func (c *quicPacketConn) WriteTo(p []byte, addr net.Addr) (int, error) {
	n, err := c.PacketConn.WriteTo(p, addr)
	if n > 0 {
		c.sentPackets.Add(1)
		c.sentBytes.Add(int64(n))
	}
	return n, err
}

func (c *quicPacketConn) ReadFrom(p []byte) (int, net.Addr, error) {
	n, addr, err := c.PacketConn.ReadFrom(p)
	if n > 0 {
		c.receivedPackets.Add(1)
		c.receivedBytes.Add(int64(n))
	}
	return n, addr, err
}

func (c *quicPacketConn) updateResult(result *QuicTestResult) {
	result.SentPackets = c.sentPackets.Load()
	result.SentBytes = c.sentBytes.Load()
	result.ReceivedPackets = c.receivedPackets.Load()
	result.ReceivedBytes = c.receivedBytes.Load()
}

func normalizeQuicTarget(input string) (target string, serverName string, err error) {
	input = strings.TrimSpace(input)
	if input == "" {
		input = defaultQuicTestHost
	}

	host, port, splitErr := net.SplitHostPort(input)
	if splitErr != nil {
		if _, parseErr := netip.ParseAddr(input); parseErr == nil {
			host = input
			port = "443"
		} else if !strings.Contains(input, ":") {
			host = input
			port = "443"
		} else {
			return "", "", fmt.Errorf("invalid QUIC target %q: %w", input, splitErr)
		}
	}

	if host == "" ||
		strings.ContainsAny(host, "[]/\\") ||
		strings.ContainsFunc(host, func(r rune) bool {
			return unicode.IsSpace(r) || unicode.IsControl(r)
		}) {
		return "", "", fmt.Errorf("invalid QUIC target host %q", host)
	}

	portNumber, parseErr := strconv.ParseUint(port, 10, 16)
	if parseErr != nil || portNumber == 0 {
		if parseErr == nil {
			parseErr = fmt.Errorf("port must be greater than zero")
		}
		return "", "", fmt.Errorf("invalid QUIC target port %q: %w", port, parseErr)
	}

	return net.JoinHostPort(host, strconv.FormatUint(portNumber, 10)), host, nil
}

func resolvedQuicUDPAddr(metadata *C.Metadata) (*net.UDPAddr, string, error) {
	if !metadata.Resolved() {
		return nil, "", fmt.Errorf("target was not resolved by proxy")
	}
	udpAddr := metadata.UDPAddr()
	if udpAddr == nil {
		return nil, "", fmt.Errorf("resolved target is not a valid UDP address")
	}

	network := "udp"
	switch {
	case udpAddr.IP.To4() != nil:
		network = "udp4"
	case udpAddr.IP.To16() != nil:
		network = "udp6"
	}
	return udpAddr, network, nil
}

// rejectLikeProxy reports whether the proxy is a nop adapter (REJECT & co.)
// whose DialContext/ListensPacketContext never return an error by themselves.
func rejectLikeProxy(proxy C.Proxy) bool {
	switch proxy.Type() {
	case C.Reject, C.RejectDrop, C.Pass, C.PassRule:
		return true
	default:
		return false
	}
}

func sendTestResult(fn func(string), result interface{}) {
	data, err := json.Marshal(result)
	if err != nil {
		logError("Error: %s", err)
		fn("")
		return
	}
	fn(string(data))
}

func handleSpeedTest(paramsString string, fn func(string)) {
	go func() {
		var params = &SpeedTestParams{}
		if err := json.Unmarshal([]byte(paramsString), params); err != nil {
			sendTestResult(fn, &SpeedTestResult{Error: fmt.Sprintf("invalid params: %s", err)})
			return
		}

		result := &SpeedTestResult{Name: params.ProxyName}

		testUrl := params.TestUrl
		if testUrl == "" {
			testUrl = defaultSpeedTestUrl
		}

		timeout := time.Duration(params.Timeout) * time.Millisecond
		if timeout <= 0 {
			timeout = defaultSpeedTestTimeout
		}

		proxy := getProxiesWithProviders()[params.ProxyName]
		if proxy == nil {
			result.Error = fmt.Sprintf("proxy %s not found", params.ProxyName)
			sendTestResult(fn, result)
			return
		}
		if rejectLikeProxy(proxy) {
			result.Error = fmt.Sprintf("proxy %s can not be tested", params.ProxyName)
			sendTestResult(fn, result)
			return
		}

		ctx, cancel := context.WithTimeout(context.Background(), timeout)
		defer cancel()

		transport := &http.Transport{
			DisableKeepAlives: true,
			TLSClientConfig:   &gotls.Config{InsecureSkipVerify: true},
			DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
				host, portString, err := net.SplitHostPort(addr)
				if err != nil {
					return nil, err
				}
				port, err := strconv.ParseUint(portString, 10, 16)
				if err != nil {
					return nil, err
				}
				metadata := &C.Metadata{
					NetWork: C.TCP,
					Host:    host,
					DstPort: uint16(port),
				}
				return proxy.DialContext(ctx, metadata)
			},
		}
		defer transport.CloseIdleConnections()

		client := &http.Client{Transport: transport}

		req, err := http.NewRequestWithContext(ctx, http.MethodGet, testUrl, nil)
		if err != nil {
			result.Error = err.Error()
			sendTestResult(fn, result)
			return
		}

		start := time.Now()
		resp, err := client.Do(req)
		if err != nil {
			result.Error = err.Error()
			sendTestResult(fn, result)
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode >= 400 {
			result.Error = fmt.Sprintf("http status %d", resp.StatusCode)
		}

		var firstByteAt time.Time
		buf := make([]byte, 32*1024)
		for {
			n, readErr := resp.Body.Read(buf)
			if n > 0 {
				if firstByteAt.IsZero() {
					firstByteAt = time.Now()
				}
				result.Bytes += int64(n)
			}
			if readErr != nil {
				if readErr != io.EOF && result.Error == "" {
					result.Error = readErr.Error()
				}
				break
			}
		}

		end := time.Now()
		if firstByteAt.IsZero() {
			// empty body: fall back to header receive time
			result.Latency = end.Sub(start).Milliseconds()
		} else {
			result.Latency = firstByteAt.Sub(start).Milliseconds()
		}

		transfer := end.Sub(firstByteAt)
		if firstByteAt.IsZero() || transfer <= 0 {
			transfer = end.Sub(start)
		}
		if seconds := transfer.Seconds(); seconds > 0 {
			result.Speed = float64(result.Bytes) / seconds
		}

		sendTestResult(fn, result)
	}()
}

func handleQuicTest(paramsString string, fn func(string)) {
	go func() {
		var params = &QuicTestParams{}
		if err := json.Unmarshal([]byte(paramsString), params); err != nil {
			sendTestResult(fn, &QuicTestResult{
				Stage: "target_parse",
				Error: fmt.Sprintf("invalid params: %s", err),
			})
			return
		}

		result := &QuicTestResult{Name: params.ProxyName, Stage: "target_parse"}
		target, serverName, err := normalizeQuicTarget(params.Host)
		if err != nil {
			result.Error = err.Error()
			sendTestResult(fn, result)
			return
		}
		result.Target = target

		timeout := time.Duration(params.Timeout) * time.Millisecond
		if timeout <= 0 {
			timeout = defaultQuicTestTimeout
		}

		result.Stage = "proxy_lookup"
		proxy := getProxiesWithProviders()[params.ProxyName]
		if proxy == nil {
			result.Error = fmt.Sprintf("proxy %s not found", params.ProxyName)
			sendTestResult(fn, result)
			return
		}

		result.Stage = "udp_capability"
		if rejectLikeProxy(proxy) {
			result.Error = fmt.Sprintf("proxy %s can not be tested", params.ProxyName)
			sendTestResult(fn, result)
			return
		}

		if !proxy.SupportUDP() {
			result.Error = fmt.Sprintf("proxy %s does not support udp", params.ProxyName)
			sendTestResult(fn, result)
			return
		}

		ctx, cancel := context.WithTimeout(context.Background(), timeout)
		defer cancel()

		metadata := &C.Metadata{NetWork: C.UDP}
		if err := metadata.SetRemoteAddress(target); err != nil {
			result.Stage = "target_parse"
			result.Error = fmt.Sprintf("set QUIC target: %v", err)
			sendTestResult(fn, result)
			return
		}

		result.Stage = "udp_relay_open"
		packetConn, err := proxy.ListenPacketContext(ctx, metadata)
		if err != nil {
			result.Error = fmt.Sprintf("open UDP relay: %v", err)
			sendTestResult(fn, result)
			return
		}
		defer packetConn.Close()

		result.Stage = "target_resolve"
		udpAddr, network, err := resolvedQuicUDPAddr(metadata)
		if err != nil {
			result.Error = err.Error()
			sendTestResult(fn, result)
			return
		}
		result.ResolvedIP = udpAddr.String()
		result.Network = network

		tlsConfig := &tls.Config{
			ServerName:         serverName,
			NextProtos:         []string{"h3"},
			InsecureSkipVerify: true,
		}

		start := time.Now()
		result.Stage = "quic_dial"
		quicConn := &quicPacketConn{PacketConn: packetConn}
		conn, err := quic.DialEarly(ctx, quicConn, udpAddr, tlsConfig, nil)
		if err != nil {
			quicConn.updateResult(result)
			if ctx.Err() != nil {
				result.Stage = "quic_handshake"
				result.Error = fmt.Sprintf(
					"QUIC handshake timeout: %v; sent=%d received=%d",
					ctx.Err(),
					result.SentPackets,
					result.ReceivedPackets,
				)
			} else if result.SentPackets > 0 {
				result.Stage = "quic_handshake"
				result.Error = fmt.Sprintf(
					"QUIC handshake failed: %v; sent=%d received=%d",
					err,
					result.SentPackets,
					result.ReceivedPackets,
				)
			} else {
				result.Error = fmt.Sprintf("start QUIC connection: %v", err)
			}
			sendTestResult(fn, result)
			return
		}
		defer conn.CloseWithError(0, "")

		result.Stage = "quic_handshake"
		select {
		case <-conn.HandshakeComplete():
		case <-conn.Context().Done():
			quicConn.updateResult(result)
			result.Error = fmt.Sprintf(
				"QUIC handshake failed: %v; sent=%d received=%d",
				context.Cause(conn.Context()),
				result.SentPackets,
				result.ReceivedPackets,
			)
			sendTestResult(fn, result)
			return
		case <-ctx.Done():
			quicConn.updateResult(result)
			result.Error = fmt.Sprintf(
				"QUIC handshake timeout: %v; sent=%d received=%d",
				ctx.Err(),
				result.SentPackets,
				result.ReceivedPackets,
			)
			sendTestResult(fn, result)
			return
		}

		quicConn.updateResult(result)
		result.Rtt = time.Since(start).Milliseconds()
		state := conn.ConnectionState()
		result.Alpn = state.TLS.NegotiatedProtocol
		result.Version = uint32(state.Version)
		result.Stage = "completed"

		sendTestResult(fn, result)
	}()
}

var unlockManager = unlocktest.NewManager(unlocktest.Runner{})

func handleUnlockTest(paramsString string, fn func(string)) {
	go func() {
		var request unlocktest.Request
		if err := json.Unmarshal([]byte(paramsString), &request); err != nil {
			sendTestResult(fn, &unlocktest.Result{Error: "invalid unlock test params"})
			return
		}
		result := unlockManager.Run(
			context.Background(),
			request,
			dialUnlockTestContext,
			func(progress unlocktest.Progress) {
				sendMessage(Message{
					Type: UnlockTestProgressMessage,
					Data: progress,
				})
			},
		)
		sendTestResult(fn, &result)
	}()
}

func handleCancelUnlockTest(runID string) bool {
	return unlockManager.Cancel(runID)
}

type unlockChainState struct {
	mu     sync.RWMutex
	chains []string
}

func (state *unlockChainState) update(chains []string) {
	state.mu.Lock()
	state.chains = append([]string(nil), chains...)
	state.mu.Unlock()
}

func (state *unlockChainState) snapshot() []string {
	state.mu.RLock()
	defer state.mu.RUnlock()
	return append([]string(nil), state.chains...)
}

type unlockTrackedConn struct {
	net.Conn
	metadata *C.Metadata
	state    *unlockChainState
	closed   chan struct{}
	closeErr error
	close    sync.Once
}

func (conn *unlockTrackedConn) OutboundChains() []string {
	return conn.state.snapshot()
}

func (conn *unlockTrackedConn) Close() error {
	conn.close.Do(func() {
		unlockChainObservers.Delete(conn.metadata)
		close(conn.closed)
		conn.closeErr = conn.Conn.Close()
	})
	return conn.closeErr
}

var unlockChainObservers sync.Map

func captureUnlockTestChain(tracker statistic.Tracker) {
	info := tracker.Info()
	if info == nil || info.Metadata == nil {
		return
	}
	value, ok := unlockChainObservers.Load(info.Metadata)
	if !ok {
		return
	}
	value.(*unlockChainState).update(info.Chain)
}

func dialUnlockTestContext(
	ctx context.Context,
	network string,
	address string,
	specialProxy string,
) (net.Conn, []string, error) {
	if network != "tcp" && network != "tcp4" && network != "tcp6" {
		return nil, nil, fmt.Errorf("unsupported unlock test network %s", network)
	}
	metadata := &C.Metadata{
		NetWork:      C.TCP,
		Type:         C.INNER,
		DNSMode:      C.DNSNormal,
		Process:      C.MihomoName,
		SpecialProxy: specialProxy,
	}
	if err := metadata.SetRemoteAddress(address); err != nil {
		return nil, nil, err
	}
	localConn, tunnelConn := N.Pipe()
	state := &unlockChainState{}
	trackedConn := &unlockTrackedConn{
		Conn:     localConn,
		metadata: metadata,
		state:    state,
		closed:   make(chan struct{}),
	}
	unlockChainObservers.Store(metadata, state)
	go T.Tunnel.HandleTCPConn(tunnelConn, metadata)
	go func() {
		select {
		case <-ctx.Done():
			_ = trackedConn.Close()
		case <-trackedConn.closed:
		}
	}()
	return trackedConn, nil, nil
}
