package unlocktest

import (
	"context"
	"crypto/tls"
	"io"
	"net"
	"net/http"
	"net/http/cookiejar"
	"sync"
)

const (
	UserAgent       = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
	MaxResponseBody = 1024 * 1024
)

type Client struct {
	HTTP         *http.Client
	mu           sync.Mutex
	chains       []string
	chainSources []outboundChainSource
	specialProxy string
}

type outboundChainSource interface {
	OutboundChains() []string
}

func NewClient(dialer DialContext, specialProxy string) *Client {
	jar, _ := cookiejar.New(nil)
	client := &Client{specialProxy: specialProxy}
	transport := &http.Transport{
		DisableKeepAlives: true,
		TLSClientConfig:   &tls.Config{MinVersion: tls.VersionTLS12},
	}
	if dialer != nil {
		transport.DialContext = func(ctx context.Context, network, address string) (net.Conn, error) {
			conn, chains, err := dialer(ctx, network, address, specialProxy)
			if err == nil {
				client.recordChains(chains)
				if source, ok := conn.(outboundChainSource); ok {
					client.recordChainSource(source)
				}
			}
			return conn, err
		}
	}
	client.HTTP = &http.Client{
		Transport: transport,
		Jar:       jar,
	}
	return client
}

func (client *Client) Close() {
	if transport, ok := client.HTTP.Transport.(*http.Transport); ok {
		transport.CloseIdleConnections()
	}
}

func (client *Client) Get(
	ctx context.Context,
	url string,
	headers map[string]string,
) (*http.Response, error) {
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	request.Header.Set("User-Agent", UserAgent)
	request.Header.Set("Accept-Language", "en-US,en;q=0.8")
	for name, value := range headers {
		request.Header.Set(name, value)
	}
	return client.HTTP.Do(request)
}

func (client *Client) ReadBody(response *http.Response) ([]byte, error) {
	return io.ReadAll(io.LimitReader(response.Body, MaxResponseBody))
}

func (client *Client) OutboundChains() []string {
	client.mu.Lock()
	chains := append([]string(nil), client.chains...)
	sources := append([]outboundChainSource(nil), client.chainSources...)
	client.mu.Unlock()
	for _, source := range sources {
		chains = appendUniqueChains(chains, source.OutboundChains())
	}
	return chains
}

func (client *Client) recordChains(chains []string) {
	client.mu.Lock()
	defer client.mu.Unlock()
	client.chains = appendUniqueChains(client.chains, chains)
}

func (client *Client) recordChainSource(source outboundChainSource) {
	client.mu.Lock()
	defer client.mu.Unlock()
	client.chainSources = append(client.chainSources, source)
}

func appendUniqueChains(destination, chains []string) []string {
	for _, chain := range chains {
		if chain == "" {
			continue
		}
		found := false
		for _, existing := range destination {
			if existing == chain {
				found = true
				break
			}
		}
		if !found {
			destination = append(destination, chain)
		}
	}
	return destination
}
