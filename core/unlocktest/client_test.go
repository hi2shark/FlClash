package unlocktest

import (
	"context"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"testing"
)

type outboundChainConn struct {
	net.Conn
	chains []string
}

func (conn *outboundChainConn) OutboundChains() []string {
	return append([]string(nil), conn.chains...)
}

func TestClientRecordsUniqueOutboundChains(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = io.WriteString(w, "ok")
	}))
	defer server.Close()

	dialer := func(ctx context.Context, network, address, specialProxy string) (net.Conn, []string, error) {
		conn, err := (&net.Dialer{}).DialContext(ctx, network, address)
		return &outboundChainConn{
			Conn:   conn,
			chains: []string{"Proxy A", "DIRECT"},
		}, nil, err
	}
	client := NewClient(dialer, "Proxy A")

	for i := 0; i < 2; i++ {
		response, err := client.Get(context.Background(), server.URL, nil)
		if err != nil {
			t.Fatal(err)
		}
		_ = response.Body.Close()
	}

	chains := client.OutboundChains()
	if len(chains) != 2 || chains[0] != "Proxy A" || chains[1] != "DIRECT" {
		t.Fatalf("outbound chains = %#v", chains)
	}
}
