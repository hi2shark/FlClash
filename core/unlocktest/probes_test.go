package unlocktest

import (
	"context"
	"io"
	"net/http"
	"strings"
	"testing"
)

type roundTripFunc func(*http.Request) (*http.Response, error)

func (function roundTripFunc) RoundTrip(request *http.Request) (*http.Response, error) {
	return function(request)
}

func fixtureClient(
	status int,
	body string,
	headers map[string]string,
) *Client {
	return &Client{
		HTTP: &http.Client{
			Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
				responseHeaders := make(http.Header)
				for name, value := range headers {
					responseHeaders.Set(name, value)
				}
				return &http.Response{
					StatusCode: status,
					Header:     responseHeaders,
					Body:       io.NopCloser(strings.NewReader(body)),
					Request:    request,
				}, nil
			}),
		},
	}
}

func runFixtureProbe(t *testing.T, id string, status int, body string) Outcome {
	t.Helper()
	target, ok := Registry()[id]
	if !ok {
		t.Fatalf("unknown target %q", id)
	}
	return target.Probe.Run(
		context.Background(),
		fixtureClient(status, body, nil),
	)
}

func TestEveryCatalogTargetHasAConfiguredProbe(t *testing.T) {
	fixture := `{
		"deviceid":"runtime-device",
		"code":0,
		"region":"US",
		"region":1,
		"country":"US",
		"country_code":"JP",
		"isoCountryCode":"JP",
		"isAllowed":true,
		"resultStatus":200,
		"markers":"chat login AbraHomeRoot.react playableVideo disneyplus storefront youtube premium max.com hulu paramountplus peacock Spotify.Entity tiktok crunchyroll media connection Playlist #EXTM3U channel4 viutv DMM TV U-NEXT TVer platform_uid kocowa watcha /ko-KR/"
	}`

	for _, target := range Catalog() {
		client := &Client{
			HTTP: &http.Client{
				Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
					body := fixture
					if strings.Contains(request.URL.Path, "token.php") {
						body = `{"animeSn":38832}`
					}
					return &http.Response{
						StatusCode: http.StatusOK,
						Header:     make(http.Header),
						Body:       io.NopCloser(strings.NewReader(body)),
						Request:    request,
					}, nil
				}),
			},
		}
		outcome := target.Probe.Run(
			context.Background(),
			client,
		)
		if outcome.Detail == "probe is not configured" {
			t.Errorf("%s still uses the placeholder probe", target.ID)
		}
		if outcome.Status != StatusUnlocked {
			t.Errorf("%s fixture status = %s, want %s (%s)", target.ID, outcome.Status, StatusUnlocked, outcome.Detail)
		}
	}
}

func TestNetflixReportsOriginalsOnlyAsPartial(t *testing.T) {
	outcome := runFixtureProbe(t, "netflix", http.StatusNotFound, "")
	if outcome.Status != StatusPartial || outcome.Reason != ReasonContentLimited {
		t.Fatalf("unexpected Netflix outcome: %#v", outcome)
	}
}

func TestBilibiliRegionErrorIsLocked(t *testing.T) {
	outcome := runFixtureProbe(
		t,
		"bilibili-hk-mo",
		http.StatusOK,
		`{"code":10004001,"message":"抱歉您所在地区不可观看"}`,
	)
	if outcome.Status != StatusLocked || outcome.Reason != ReasonGeoBlocked {
		t.Fatalf("unexpected Bilibili outcome: %#v", outcome)
	}
}

func TestRateLimitIsAnErrorInsteadOfLocked(t *testing.T) {
	outcome := runFixtureProbe(t, "claude", http.StatusTooManyRequests, "")
	if outcome.Status != StatusError || outcome.Reason != ReasonRateLimited {
		t.Fatalf("unexpected Claude outcome: %#v", outcome)
	}
}

func TestUnrecognizedSuccessfulResponseIsAnError(t *testing.T) {
	outcome := runFixtureProbe(t, "dazn", http.StatusOK, `{}`)
	if outcome.Status != StatusError || outcome.Reason != ReasonUnexpectedResponse {
		t.Fatalf("unexpected DAZN outcome: %#v", outcome)
	}
}

func TestNHKCountryCodeDistinguishesJapanFromOtherRegions(t *testing.T) {
	unlocked := runFixtureProbe(
		t,
		"nhk-plus",
		http.StatusOK,
		`{"country_code":"JP"}`,
	)
	if unlocked.Status != StatusUnlocked || unlocked.Region != "JP" {
		t.Fatalf("unexpected NHK+ Japan outcome: %#v", unlocked)
	}

	locked := runFixtureProbe(
		t,
		"nhk-plus",
		http.StatusOK,
		`{"country_code":"US"}`,
	)
	if locked.Status != StatusLocked ||
		locked.Reason != ReasonGeoBlocked ||
		locked.Region != "US" {
		t.Fatalf("unexpected NHK+ non-Japan outcome: %#v", locked)
	}
}

func TestTraceRegionIsExtracted(t *testing.T) {
	outcome := runFixtureProbe(t, "chatgpt", http.StatusOK, "fl=1\nloc=JP\n")
	if outcome.Status != StatusUnlocked || outcome.Region != "JP" {
		t.Fatalf("unexpected ChatGPT outcome: %#v", outcome)
	}
}

func TestBahamutBootstrapsRuntimeDeviceSession(t *testing.T) {
	requests := 0
	client := &Client{
		HTTP: &http.Client{
			Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
				requests++
				body := `{"deviceid":"runtime-device"}`
				if strings.Contains(request.URL.Path, "token.php") {
					if request.URL.Query().Get("device") != "runtime-device" {
						t.Fatalf("runtime device id was not forwarded: %s", request.URL)
					}
					body = `{"animeSn":38832}`
				}
				return &http.Response{
					StatusCode: http.StatusOK,
					Header:     make(http.Header),
					Body:       io.NopCloser(strings.NewReader(body)),
					Request:    request,
				}, nil
			}),
		},
	}

	outcome := Registry()["bahamut-anime"].Probe.Run(context.Background(), client)
	if requests != 2 {
		t.Fatalf("bootstrap requests = %d, want 2", requests)
	}
	if outcome.Status != StatusUnlocked || outcome.Region != "TW" {
		t.Fatalf("unexpected Bahamut outcome: %#v", outcome)
	}
}
