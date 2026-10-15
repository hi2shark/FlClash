package unlocktest

import (
	"context"
	"net"
	"time"
)

type Group string

const (
	GroupAI             Group = "ai"
	GroupGlobalMedia    Group = "globalMedia"
	GroupEurope         Group = "europe"
	GroupHongKongTaiwan Group = "hongKongTaiwan"
	GroupJapan          Group = "japan"
	GroupKorea          Group = "korea"
)

type RouteMode string

const (
	RouteModeAppRoute RouteMode = "appRoute"
	RouteModeProxy    RouteMode = "proxy"
)

type Status string

const (
	StatusUnlocked Status = "unlocked"
	StatusPartial  Status = "partial"
	StatusLocked   Status = "locked"
	StatusError    Status = "error"
	StatusUntested Status = "untested"
)

type Reason string

const (
	ReasonNone               Reason = ""
	ReasonContentLimited     Reason = "contentLimited"
	ReasonGeoBlocked         Reason = "geoBlocked"
	ReasonVPNBlocked         Reason = "vpnBlocked"
	ReasonRateLimited        Reason = "rateLimited"
	ReasonTimeout            Reason = "timeout"
	ReasonNetworkError       Reason = "networkError"
	ReasonBootstrapFailed    Reason = "bootstrapFailed"
	ReasonUnexpectedResponse Reason = "unexpectedResponse"
)

type Request struct {
	RunID     string        `json:"run-id"`
	RouteMode RouteMode     `json:"route-mode"`
	ProxyName string        `json:"proxy-name,omitempty"`
	TargetIDs []string      `json:"target-ids"`
	Timeout   time.Duration `json:"-"`
	TimeoutMS int           `json:"timeout,omitempty"`
}

func (request Request) EffectiveTimeout() time.Duration {
	if request.Timeout > 0 {
		return request.Timeout
	}
	if request.TimeoutMS > 0 {
		return time.Duration(request.TimeoutMS) * time.Millisecond
	}
	return 10 * time.Second
}

type Item struct {
	ID              string   `json:"id"`
	Status          Status   `json:"status"`
	Reason          Reason   `json:"reason,omitempty"`
	Region          string   `json:"region,omitempty"`
	Latency         int64    `json:"latency"`
	OutboundChains  []string `json:"outbound-chains,omitempty"`
	SanitizedDetail string   `json:"sanitized-detail,omitempty"`
}

type Result struct {
	RunID     string    `json:"run-id"`
	RouteMode RouteMode `json:"route-mode"`
	ProxyName string    `json:"proxy-name,omitempty"`
	Results   []Item    `json:"results"`
	Cancelled bool      `json:"cancelled,omitempty"`
	Error     string    `json:"error,omitempty"`
}

type Progress struct {
	RunID     string `json:"run-id"`
	Completed int    `json:"completed"`
	Total     int    `json:"total"`
	Item      Item   `json:"item"`
}

type Outcome struct {
	Status Status
	Reason Reason
	Region string
	Detail string
}

type DialContext func(
	ctx context.Context,
	network string,
	address string,
	specialProxy string,
) (net.Conn, []string, error)

type Probe interface {
	Run(ctx context.Context, client *Client) Outcome
}

type ProbeFunc func(ctx context.Context, client *Client) Outcome

func (function ProbeFunc) Run(ctx context.Context, client *Client) Outcome {
	return function(ctx, client)
}

type Target struct {
	ID    string
	Group Group
	Probe Probe
}
