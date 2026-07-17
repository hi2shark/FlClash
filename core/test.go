package main

import (
	"context"
	gotls "crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"strconv"
	"time"

	C "github.com/metacubex/mihomo/constant"
	quic "github.com/metacubex/quic-go"
	"github.com/metacubex/tls"
)

const (
	defaultSpeedTestUrl     = "https://speed.cloudflare.com/__down?bytes=25000000"
	defaultSpeedTestTimeout = 15 * time.Second
	defaultQuicTestHost     = "www.google.com:443"
	defaultQuicTestTimeout  = 5 * time.Second
)

type SpeedTestResult struct {
	Name    string  `json:"name"`
	Latency int64   `json:"latency"` // time to first byte, ms
	Speed   float64 `json:"speed"`   // bytes/sec
	Bytes   int64   `json:"bytes"`
	Error   string  `json:"error"`
}

type QuicTestResult struct {
	Name    string `json:"name"`
	Rtt     int64  `json:"rtt"` // handshake duration, ms
	Alpn    string `json:"alpn"`
	Version uint32 `json:"version"` // QUIC version number
	Error   string `json:"error"`
}

// quicPacketConn adapts a mihomo constant.PacketConn to net.PacketConn for quic-go.
type quicPacketConn struct {
	C.PacketConn
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
			sendTestResult(fn, &QuicTestResult{Error: fmt.Sprintf("invalid params: %s", err)})
			return
		}

		result := &QuicTestResult{Name: params.ProxyName}

		host := params.Host
		if host == "" {
			host = defaultQuicTestHost
		}

		timeout := time.Duration(params.Timeout) * time.Millisecond
		if timeout <= 0 {
			timeout = defaultQuicTestTimeout
		}

		serverName := host
		if h, _, err := net.SplitHostPort(host); err == nil {
			serverName = h
		} else {
			host = net.JoinHostPort(host, "443")
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
		if !proxy.SupportUDP() {
			result.Error = fmt.Sprintf("proxy %s does not support udp", params.ProxyName)
			sendTestResult(fn, result)
			return
		}

		_, portString, err := net.SplitHostPort(host)
		if err != nil {
			result.Error = err.Error()
			sendTestResult(fn, result)
			return
		}
		port, err := strconv.ParseUint(portString, 10, 16)
		if err != nil {
			result.Error = err.Error()
			sendTestResult(fn, result)
			return
		}

		ctx, cancel := context.WithTimeout(context.Background(), timeout)
		defer cancel()

		metadata := &C.Metadata{
			NetWork: C.UDP,
			Host:    serverName,
			DstPort: uint16(port),
		}
		packetConn, err := proxy.ListenPacketContext(ctx, metadata)
		if err != nil {
			result.Error = err.Error()
			sendTestResult(fn, result)
			return
		}
		defer packetConn.Close()

		udpAddr, err := net.ResolveUDPAddr("udp", host)
		if err != nil {
			result.Error = err.Error()
			sendTestResult(fn, result)
			return
		}

		tlsConfig := &tls.Config{
			ServerName:         serverName,
			NextProtos:         []string{"h3"},
			InsecureSkipVerify: true,
		}

		start := time.Now()
		conn, err := quic.DialEarly(ctx, &quicPacketConn{packetConn}, udpAddr, tlsConfig, nil)
		if err != nil {
			result.Error = err.Error()
			sendTestResult(fn, result)
			return
		}
		defer conn.CloseWithError(0, "")

		select {
		case <-conn.HandshakeComplete():
		case <-ctx.Done():
			result.Error = ctx.Err().Error()
			sendTestResult(fn, result)
			return
		}

		result.Rtt = time.Since(start).Milliseconds()
		state := conn.ConnectionState()
		result.Alpn = state.TLS.NegotiatedProtocol
		result.Version = uint32(state.Version)

		sendTestResult(fn, result)
	}()
}
