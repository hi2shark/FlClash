package main

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/adapter/outbound"
	"github.com/metacubex/mihomo/adapter/outboundgroup"
	"github.com/metacubex/mihomo/adapter/provider"
	C "github.com/metacubex/mihomo/constant"
	P "github.com/metacubex/mihomo/constant/provider"
	"github.com/metacubex/mihomo/tunnel"
)

func TestHandleGetProxiesIncludesProviderProxies(t *testing.T) {
	homeDir := t.TempDir()
	previousHomeDir := C.Path.HomeDir()
	C.SetHomeDir(homeDir)
	t.Cleanup(func() {
		C.SetHomeDir(previousHomeDir)
		tunnel.UpdateProxies(map[string]C.Proxy{}, map[string]P.ProxyProvider{})
	})

	err := os.WriteFile(
		filepath.Join(homeDir, "config.yaml"),
		[]byte(`proxy-groups:
  - name: manual
    type: select
    use:
      - test-provider
`),
		0o644,
	)
	if err != nil {
		t.Fatal(err)
	}

	directProxy := adapter.NewProxy(outbound.NewDirect())
	providerProxy := adapter.NewProxy(
		outbound.NewDirectWithOption(outbound.DirectOption{Name: "provider-node"}),
	)
	healthCheck := provider.NewHealthCheck(
		[]C.Proxy{providerProxy},
		"",
		5000,
		0,
		true,
		nil,
	)
	proxyProvider, err := provider.NewCompatibleProvider(
		"test-provider",
		[]C.Proxy{providerProxy},
		healthCheck,
	)
	if err != nil {
		t.Fatal(err)
	}

	group, err := outboundgroup.NewSelector(
		outboundgroup.GroupCommonOption{Name: "manual"},
		outboundgroup.SelectorOption{},
		directProxy,
		[]P.ProxyProvider{proxyProvider},
	)
	if err != nil {
		t.Fatal(err)
	}

	tunnel.UpdateProxies(
		map[string]C.Proxy{
			"DIRECT": directProxy,
			"manual": adapter.NewProxy(group),
		},
		map[string]P.ProxyProvider{
			"test-provider": proxyProvider,
		},
	)

	proxiesData := handleGetProxies()
	if _, ok := proxiesData.Proxies["provider-node"]; !ok {
		t.Fatalf("expected provider proxy to be returned in Proxies map")
	}
}
