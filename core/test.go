package main

import (
	"context"
	gotls "crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/netip"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"
	"unicode"

	C "github.com/metacubex/mihomo/constant"
	quic "github.com/metacubex/quic-go"
	"github.com/metacubex/tls"
)

const (
	defaultSpeedTestUrl     = "https://speed.cloudflare.com/__down?bytes=25000000"
	defaultSpeedTestTimeout = 15 * time.Second
	defaultQuicTestHost     = "cloudflare-quic.com:443"
	defaultQuicTestTimeout  = 8 * time.Second

	defaultUnlockTestTimeout = 5 * time.Second
	unlockTestConcurrency    = 4
	unlockTestMaxBodyBytes   = 256 * 1024
	unlockTestUserAgent      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
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

type UnlockTestResultItem struct {
	Id       string `json:"id"`
	Status   int    `json:"status"`
	Latency  int64  `json:"latency"` // time to response headers, ms
	Region   string `json:"region"`
	Unlocked bool   `json:"unlocked"`
	Error    string `json:"error"`
}

type UnlockTestResult struct {
	Name    string                 `json:"name"`
	Results []UnlockTestResultItem `json:"results"`
	Error   string                 `json:"error"`
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

func handleUnlockTest(paramsString string, fn func(string)) {
	go func() {
		var params = &UnlockTestParams{}
		if err := json.Unmarshal([]byte(paramsString), params); err != nil {
			sendTestResult(fn, &UnlockTestResult{Error: fmt.Sprintf("invalid params: %s", err)})
			return
		}

		result := &UnlockTestResult{Name: params.ProxyName}

		if len(params.Tests) == 0 {
			result.Error = "no unlock test targets"
			sendTestResult(fn, result)
			return
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

		timeout := time.Duration(params.Timeout) * time.Millisecond
		if timeout <= 0 {
			timeout = defaultUnlockTestTimeout
		}

		items := make([]UnlockTestResultItem, len(params.Tests))
		var wg sync.WaitGroup
		semaphore := make(chan struct{}, unlockTestConcurrency)
		for i, item := range params.Tests {
			wg.Add(1)
			go func(index int, testItem UnlockTestItem) {
				defer wg.Done()
				semaphore <- struct{}{}
				defer func() { <-semaphore }()
				items[index] = runUnlockTestItem(proxy, testItem, timeout)
			}(i, item)
		}
		wg.Wait()
		result.Results = items
		sendTestResult(fn, result)
	}()
}

func runUnlockTestItem(proxy C.Proxy, item UnlockTestItem, timeout time.Duration) UnlockTestResultItem {
	result := UnlockTestResultItem{Id: item.Id}

	if item.Url == "" {
		result.Error = "empty test url"
		return result
	}

	method := strings.ToUpper(strings.TrimSpace(item.Method))
	if method == "" {
		method = http.MethodGet
	}

	expectedStatus := item.ExpectedStatus
	if len(expectedStatus) == 0 {
		expectedStatus = []int{http.StatusOK}
	}

	var regionRegex *regexp.Regexp
	if item.RegionRegex != "" {
		compiled, err := regexp.Compile(item.RegionRegex)
		if err != nil {
			result.Error = fmt.Sprintf("invalid region regex: %s", err)
			return result
		}
		regionRegex = compiled
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

	// Inspect the first response instead of following redirects: region
	// blocks usually show up as an immediate redirect or error status.
	client := &http.Client{
		Transport: transport,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}

	req, err := http.NewRequestWithContext(ctx, method, item.Url, nil)
	if err != nil {
		result.Error = err.Error()
		return result
	}
	req.Header.Set("User-Agent", unlockTestUserAgent)

	start := time.Now()
	resp, err := client.Do(req)
	if err != nil {
		result.Error = err.Error()
		return result
	}
	defer resp.Body.Close()

	result.Latency = time.Since(start).Milliseconds()
	result.Status = resp.StatusCode

	if regionRegex != nil {
		body, err := io.ReadAll(io.LimitReader(resp.Body, unlockTestMaxBodyBytes))
		if err != nil {
			result.Error = err.Error()
			return result
		}
		if matches := regionRegex.FindSubmatch(body); len(matches) > 1 {
			result.Region = string(matches[1])
		}
	} else {
		_, _ = io.Copy(io.Discard, resp.Body)
	}

	for _, status := range expectedStatus {
		if resp.StatusCode == status {
			result.Unlocked = true
			break
		}
	}

	return result
}
