package unlocktest

import (
	"context"
	"encoding/json"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"strings"
)

type probeRule struct {
	URL             string
	Headers         map[string]string
	UnlockedMarkers []string
	PartialMarkers  []string
	LockedMarkers   []string
	SuccessOn2xx    bool
	PartialOn2xx    bool
	ForbiddenReason Reason
}

type responseData struct {
	status int
	body   string
}

func simpleProbe(rule probeRule) Probe {
	return ProbeFunc(func(ctx context.Context, client *Client) Outcome {
		response, err := fetch(ctx, client, rule.URL, rule.Headers)
		if err != nil {
			return outcomeFromError(err)
		}
		return classifyResponse(response, rule)
	})
}

func regionalAIProbe(pageURL, traceURL string) Probe {
	return ProbeFunc(func(ctx context.Context, client *Client) Outcome {
		page, err := fetch(ctx, client, pageURL, nil)
		if err != nil {
			return outcomeFromError(err)
		}
		pageOutcome := classifyResponse(page, probeRule{
			UnlockedMarkers: []string{"chat", "login", "sign in", "loc="},
			LockedMarkers: []string{
				"unsupported_country",
				"not available in your country",
				"not available in your region",
				"geo_blocked",
			},
			SuccessOn2xx:    true,
			ForbiddenReason: ReasonVPNBlocked,
		})
		if pageOutcome.Status != StatusUnlocked {
			return pageOutcome
		}

		trace, err := fetch(ctx, client, traceURL, nil)
		if err != nil {
			return Outcome{
				Status: StatusPartial,
				Reason: ReasonContentLimited,
				Detail: "service is reachable but region could not be confirmed",
			}
		}
		if trace.status == http.StatusTooManyRequests {
			return rateLimitedOutcome()
		}
		region := extractRegion(trace.body)
		return Outcome{Status: StatusUnlocked, Region: region}
	})
}

func netflixProbe() Probe {
	const firstTitle = "https://www.netflix.com/title/70143836"
	const secondTitle = "https://www.netflix.com/title/81280792"
	return ProbeFunc(func(ctx context.Context, client *Client) Outcome {
		first, err := fetch(ctx, client, firstTitle, nil)
		if err != nil {
			return outcomeFromError(err)
		}
		second, err := fetch(ctx, client, secondTitle, nil)
		if err != nil {
			return outcomeFromError(err)
		}
		if first.status == http.StatusTooManyRequests ||
			second.status == http.StatusTooManyRequests {
			return rateLimitedOutcome()
		}
		if first.status == http.StatusForbidden && second.status == http.StatusForbidden {
			return Outcome{
				Status: StatusLocked,
				Reason: ReasonVPNBlocked,
				Detail: "Netflix rejected this network",
			}
		}
		if first.status == http.StatusNotFound && second.status == http.StatusNotFound {
			return Outcome{
				Status: StatusPartial,
				Reason: ReasonContentLimited,
				Detail: "only Netflix originals appear to be available",
			}
		}
		for _, response := range []responseData{first, second} {
			lowerBody := strings.ToLower(response.body)
			if response.status >= 200 && response.status < 400 &&
				(strings.Contains(lowerBody, `property="og:video"`) ||
					strings.Contains(lowerBody, `data-uia="episodes"`) ||
					strings.Contains(lowerBody, "playablevideo")) {
				return Outcome{
					Status: StatusUnlocked,
					Region: extractRegion(response.body),
				}
			}
		}
		return Outcome{
			Status: StatusError,
			Reason: ReasonUnexpectedResponse,
			Detail: "Netflix returned an unrecognized response",
		}
	})
}

func bilibiliProbe(endpoint string) Probe {
	return ProbeFunc(func(ctx context.Context, client *Client) Outcome {
		response, err := fetch(ctx, client, endpoint, nil)
		if err != nil {
			return outcomeFromError(err)
		}
		if response.status == http.StatusTooManyRequests {
			return rateLimitedOutcome()
		}
		lowerBody := strings.ToLower(response.body)
		if strings.Contains(response.body, "抱歉您所在地区不可观看") ||
			strings.Contains(lowerBody, "the area is inaccessible") ||
			containsAny(lowerBody, []string{`"code":10004001`, `"code":10003003`, `"code":-10403`}) {
			return Outcome{
				Status: StatusLocked,
				Reason: ReasonGeoBlocked,
				Detail: "title is unavailable in this region",
			}
		}
		if response.status == http.StatusPreconditionFailed {
			return Outcome{
				Status: StatusPartial,
				Reason: ReasonContentLimited,
				Detail: "service is reachable but playback was restricted",
			}
		}
		if containsJSONCode(response.body, 0) {
			return Outcome{Status: StatusUnlocked}
		}
		return Outcome{
			Status: StatusError,
			Reason: ReasonUnexpectedResponse,
			Detail: "Bilibili returned an unrecognized response",
		}
	})
}

func bahamutProbe() Probe {
	return ProbeFunc(func(ctx context.Context, client *Client) Outcome {
		deviceResponse, err := fetch(
			ctx,
			client,
			"https://ani.gamer.com.tw/ajax/getdeviceid.php",
			map[string]string{"x-custom-headers": "true"},
		)
		if err != nil {
			return outcomeFromError(err)
		}
		if deviceResponse.status == http.StatusTooManyRequests {
			return rateLimitedOutcome()
		}
		var device struct {
			DeviceID string `json:"deviceid"`
		}
		if err := json.Unmarshal([]byte(deviceResponse.body), &device); err != nil ||
			device.DeviceID == "" {
			if containsAny(strings.ToLower(deviceResponse.body), []string{
				"just a moment", "系統異常回報",
			}) {
				return Outcome{
					Status: StatusLocked,
					Reason: ReasonVPNBlocked,
					Detail: "Bahamut rejected this network",
				}
			}
			return Outcome{
				Status: StatusError,
				Reason: ReasonBootstrapFailed,
				Detail: "could not create a temporary Bahamut session",
			}
		}

		tokenURL := "https://ani.gamer.com.tw/ajax/token.php?adID=89422&sn=38832&device=" +
			url.QueryEscape(device.DeviceID)
		tokenResponse, err := fetch(
			ctx,
			client,
			tokenURL,
			map[string]string{"x-custom-headers": "true"},
		)
		if err != nil {
			return outcomeFromError(err)
		}
		var tokenResult struct {
			AnimeSN int `json:"animeSn"`
		}
		if err := json.Unmarshal([]byte(tokenResponse.body), &tokenResult); err == nil &&
			tokenResult.AnimeSN != 0 {
			return Outcome{Status: StatusUnlocked, Region: "TW"}
		}
		if strings.Contains(tokenResponse.body, "授權因素無法在您的所在地區播放") ||
			tokenResponse.status == http.StatusForbidden ||
			tokenResponse.status == http.StatusNotFound {
			return Outcome{
				Status: StatusLocked,
				Reason: ReasonGeoBlocked,
				Detail: "title is unavailable in this region",
			}
		}
		return Outcome{
			Status: StatusError,
			Reason: ReasonUnexpectedResponse,
			Detail: "Bahamut returned an unrecognized response",
		}
	})
}

func fetch(
	ctx context.Context,
	client *Client,
	endpoint string,
	headers map[string]string,
) (responseData, error) {
	response, err := client.Get(ctx, endpoint, headers)
	if err != nil {
		return responseData{}, err
	}
	defer response.Body.Close()
	body, err := client.ReadBody(response)
	if err != nil {
		return responseData{}, err
	}
	return responseData{
		status: response.StatusCode,
		body:   string(body),
	}, nil
}

func classifyResponse(response responseData, rule probeRule) Outcome {
	if response.status == http.StatusTooManyRequests {
		return rateLimitedOutcome()
	}
	if response.status == http.StatusUnavailableForLegalReasons {
		return Outcome{
			Status: StatusLocked,
			Reason: ReasonGeoBlocked,
			Detail: "service is unavailable in this region",
		}
	}
	if response.status == http.StatusForbidden {
		reason := rule.ForbiddenReason
		if reason == ReasonNone {
			reason = ReasonGeoBlocked
		}
		return Outcome{
			Status: StatusLocked,
			Reason: reason,
			Detail: "service rejected this network",
		}
	}
	if response.status >= 500 {
		return Outcome{
			Status: StatusError,
			Reason: ReasonUnexpectedResponse,
			Detail: "service is temporarily unavailable",
		}
	}

	lowerBody := strings.ToLower(response.body)
	region := extractRegion(response.body)
	if containsAny(lowerBody, lowerStrings(rule.LockedMarkers)) {
		return Outcome{
			Status: StatusLocked,
			Reason: ReasonGeoBlocked,
			Region: region,
			Detail: "service is unavailable in this region",
		}
	}
	if containsAny(lowerBody, lowerStrings(rule.PartialMarkers)) {
		return Outcome{
			Status: StatusPartial,
			Reason: ReasonContentLimited,
			Region: region,
			Detail: "only part of the catalog is available",
		}
	}
	if containsAny(lowerBody, lowerStrings(rule.UnlockedMarkers)) {
		return Outcome{Status: StatusUnlocked, Region: region}
	}
	if response.status >= 200 && response.status < 400 {
		if rule.SuccessOn2xx {
			return Outcome{Status: StatusUnlocked, Region: region}
		}
		if rule.PartialOn2xx {
			return Outcome{
				Status: StatusPartial,
				Reason: ReasonContentLimited,
				Region: region,
				Detail: "landing page is reachable; playback was not confirmed",
			}
		}
	}
	return Outcome{
		Status: StatusError,
		Reason: ReasonUnexpectedResponse,
		Region: region,
		Detail: "service returned an unrecognized response",
	}
}

func extractRegion(body string) string {
	expressions := []*regexp.Regexp{
		regexp.MustCompile(`(?mi)^loc=([A-Za-z0-9]{2,3})$`),
		regexp.MustCompile(`(?i)"(?:country|countryCode|country_code|region|regionCode|isoCountryCode|market)"\s*:\s*"([A-Za-z]{2,3})"`),
		regexp.MustCompile(`(?i)data-country\s*=\s*"([A-Za-z]{2,3})"`),
		regexp.MustCompile(`(?i)'code'\s*:\s*'([A-Za-z]{2,3})'`),
	}
	for _, expression := range expressions {
		matches := expression.FindStringSubmatch(body)
		if len(matches) > 1 {
			return strings.ToUpper(matches[1])
		}
	}
	return ""
}

func containsJSONCode(body string, expected int) bool {
	var response struct {
		Code int `json:"code"`
	}
	if json.Unmarshal([]byte(body), &response) == nil {
		return response.Code == expected
	}
	return strings.Contains(
		strings.ReplaceAll(body, " ", ""),
		`"code":`+strconv.Itoa(expected),
	)
}

func containsAny(body string, markers []string) bool {
	for _, marker := range markers {
		if marker != "" && strings.Contains(body, marker) {
			return true
		}
	}
	return false
}

func lowerStrings(values []string) []string {
	lowered := make([]string, len(values))
	for index, value := range values {
		lowered[index] = strings.ToLower(value)
	}
	return lowered
}

func rateLimitedOutcome() Outcome {
	return Outcome{
		Status: StatusError,
		Reason: ReasonRateLimited,
		Detail: "service rate limited the probe",
	}
}

func outcomeFromError(err error) Outcome {
	item := itemFromError("", err, 0, nil)
	return Outcome{
		Status: item.Status,
		Reason: item.Reason,
		Detail: item.SanitizedDetail,
	}
}

func jsonAllowedProbe(
	endpoint string,
	allowedMarkers []string,
	lockedMarkers []string,
	region string,
) Probe {
	return ProbeFunc(func(ctx context.Context, client *Client) Outcome {
		response, err := fetch(ctx, client, endpoint, nil)
		if err != nil {
			return outcomeFromError(err)
		}
		outcome := classifyResponse(response, probeRule{
			UnlockedMarkers: allowedMarkers,
			LockedMarkers:   lockedMarkers,
			SuccessOn2xx:    false,
		})
		if outcome.Status == StatusUnlocked && outcome.Region == "" {
			outcome.Region = region
		}
		return outcome
	})
}

func jsonCountryProbe(endpoint, key, allowedRegion string) Probe {
	return ProbeFunc(func(ctx context.Context, client *Client) Outcome {
		response, err := fetch(ctx, client, endpoint, nil)
		if err != nil {
			return outcomeFromError(err)
		}
		if response.status == http.StatusTooManyRequests {
			return rateLimitedOutcome()
		}
		if response.status == http.StatusForbidden ||
			response.status == http.StatusUnavailableForLegalReasons {
			return Outcome{
				Status: StatusLocked,
				Reason: ReasonGeoBlocked,
				Detail: "service is unavailable in this region",
			}
		}
		if response.status < 200 || response.status >= 400 {
			return Outcome{
				Status: StatusError,
				Reason: ReasonUnexpectedResponse,
				Detail: "service returned an unrecognized response",
			}
		}

		var payload map[string]any
		if err := json.Unmarshal([]byte(response.body), &payload); err != nil {
			return Outcome{
				Status: StatusError,
				Reason: ReasonUnexpectedResponse,
				Detail: "service returned an unrecognized response",
			}
		}
		region, _ := payload[key].(string)
		region = strings.ToUpper(strings.TrimSpace(region))
		if region == "" {
			return Outcome{
				Status: StatusError,
				Reason: ReasonUnexpectedResponse,
				Detail: "service response did not include a region",
			}
		}
		if region != strings.ToUpper(allowedRegion) {
			return Outcome{
				Status: StatusLocked,
				Reason: ReasonGeoBlocked,
				Region: region,
				Detail: "service is unavailable in this region",
			}
		}
		return Outcome{Status: StatusUnlocked, Region: region}
	})
}
