package unlocktest

func Catalog() []Target {
	return []Target{
		target("chatgpt", GroupAI, regionalAIProbe(
			"https://ios.chat.openai.com/",
			"https://chatgpt.com/cdn-cgi/trace",
		)),
		target("claude", GroupAI, regionalAIProbe(
			"https://claude.ai/",
			"https://claude.ai/cdn-cgi/trace",
		)),
		target("gemini", GroupAI, simpleProbe(probeRule{
			URL:             "https://gemini.google.com/",
			LockedMarkers:   []string{"not available in your country", "45631641,null,false"},
			UnlockedMarkers: []string{"45631641,null,true", "45617354,null,true"},
			SuccessOn2xx:    true,
			ForbiddenReason: ReasonVPNBlocked,
		})),
		target("copilot", GroupAI, simpleProbe(probeRule{
			URL:             "https://copilot.microsoft.com/c/api/user?api-version=2",
			LockedMarkers:   []string{"unsupported region", "not available"},
			UnlockedMarkers: []string{`"regionCode"`},
			SuccessOn2xx:    true,
			ForbiddenReason: ReasonVPNBlocked,
		})),
		target("perplexity", GroupAI, regionalAIProbe(
			"https://www.perplexity.ai/",
			"https://www.perplexity.ai/cdn-cgi/trace",
		)),
		target("grok", GroupAI, regionalAIProbe(
			"https://grok.com/",
			"https://grok.com/cdn-cgi/trace",
		)),
		target("meta-ai", GroupAI, simpleProbe(probeRule{
			URL:             "https://www.meta.ai/ajax",
			LockedMarkers:   []string{"GeoBlockedErrorRoot"},
			UnlockedMarkers: []string{"AbraHomeRoot", "HomeRootQuery", "KadabraRootContainer"},
			PartialOn2xx:    true,
			ForbiddenReason: ReasonVPNBlocked,
		})),
		target("sora", GroupAI, regionalAIProbe(
			"https://sora.com/",
			"https://sora.com/cdn-cgi/trace",
		)),
		target("deepseek", GroupAI, regionalAIProbe(
			"https://chat.deepseek.com/",
			"https://chat.deepseek.com/cdn-cgi/trace",
		)),
		target("netflix", GroupGlobalMedia, netflixProbe()),
		target("disney-plus", GroupGlobalMedia, simpleProbe(probeRule{
			URL:             "https://www.disneyplus.com/",
			LockedMarkers:   []string{"not available in your region", "not available in your country"},
			PartialMarkers:  []string{"preview mode"},
			UnlockedMarkers: []string{"disneyplus", "disney+"},
			PartialOn2xx:    true,
			ForbiddenReason: ReasonVPNBlocked,
		})),
		target("youtube-premium", GroupGlobalMedia, simpleProbe(probeRule{
			URL:             "https://www.youtube.com/premium",
			LockedMarkers:   []string{"not available in your country", "premium is not available"},
			UnlockedMarkers: []string{"youtube premium", "ytInitialData"},
			SuccessOn2xx:    true,
		})),
		target("prime-video", GroupGlobalMedia, simpleProbe(probeRule{
			URL:             "https://www.primevideo.com/",
			LockedMarkers:   []string{"service area restriction", "not available in your location"},
			UnlockedMarkers: []string{"storefront", "prime video"},
			PartialOn2xx:    true,
		})),
		target("max", GroupGlobalMedia, simpleProbe(probeRule{
			URL:             "https://www.max.com/",
			LockedMarkers:   []string{"not available in your region", "not yet available"},
			UnlockedMarkers: []string{"max.com", "streaming"},
			PartialOn2xx:    true,
			ForbiddenReason: ReasonVPNBlocked,
		})),
		target("hulu", GroupGlobalMedia, simpleProbe(probeRule{
			URL:             "https://www.hulu.com/",
			LockedMarkers:   []string{"GEO_BLOCKED", "not available in your region"},
			UnlockedMarkers: []string{"hulu", "LOGIN_BAD_REQUEST"},
			PartialOn2xx:    true,
			ForbiddenReason: ReasonVPNBlocked,
		})),
		target("paramount-plus", GroupGlobalMedia, simpleProbe(probeRule{
			URL:             "https://www.paramountplus.com/",
			LockedMarkers:   []string{"not available in your region", "geo-location error"},
			UnlockedMarkers: []string{"paramount+", "paramountplus"},
			PartialOn2xx:    true,
		})),
		target("peacock", GroupGlobalMedia, simpleProbe(probeRule{
			URL:             "https://www.peacocktv.com/",
			LockedMarkers:   []string{"not yet available in your territory", "geo restriction"},
			UnlockedMarkers: []string{"peacock", "watch for free"},
			PartialOn2xx:    true,
			ForbiddenReason: ReasonVPNBlocked,
		})),
		target("spotify", GroupGlobalMedia, simpleProbe(probeRule{
			URL:             "https://open.spotify.com/",
			LockedMarkers:   []string{"not available in your country"},
			UnlockedMarkers: []string{"Spotify.Entity", "market"},
			PartialOn2xx:    true,
		})),
		target("tiktok", GroupGlobalMedia, simpleProbe(probeRule{
			URL:             "https://www.tiktok.com/explore",
			LockedMarkers:   []string{"/hk/notfound", "region_unavailable"},
			UnlockedMarkers: []string{"region", "tiktok"},
			SuccessOn2xx:    true,
			ForbiddenReason: ReasonVPNBlocked,
		})),
		target("dazn", GroupGlobalMedia, simpleProbe(probeRule{
			URL:             "https://startup.core.indazn.com/v1/main/web?Platform=web&LandingPageKey=generic&Brand=dazn",
			LockedMarkers:   []string{`"IsAllowed":false`, `"isAllowed":false`},
			UnlockedMarkers: []string{`"IsAllowed":true`, `"isAllowed":true`},
			SuccessOn2xx:    false,
		})),
		target("crunchyroll", GroupGlobalMedia, simpleProbe(probeRule{
			URL:             "https://www.crunchyroll.com/",
			LockedMarkers:   []string{"not available in your region"},
			UnlockedMarkers: []string{"crunchyroll"},
			PartialOn2xx:    true,
		})),
		target("bbc-iplayer", GroupEurope, simpleProbe(probeRule{
			URL:             "https://open.live.bbc.co.uk/mediaselector/6/select/version/2.0/mediaset/pc/vpid/bbc_one_london/format/json",
			LockedMarkers:   []string{"geolocation", "notuk"},
			UnlockedMarkers: []string{"media", "connection"},
			SuccessOn2xx:    true,
		})),
		target("itvx", GroupEurope, simpleProbe(probeRule{
			URL:             "https://simulcast.itv.com/playlist/itvonline/ITV",
			LockedMarkers:   []string{"Outside Of Allowed Geographic Region"},
			UnlockedMarkers: []string{"Playlist", "#EXTM3U"},
			SuccessOn2xx:    true,
		})),
		target("channel-4", GroupEurope, simpleProbe(probeRule{
			URL:             "https://www.channel4.com/simulcast/channels/C4",
			LockedMarkers:   []string{"not available in your region"},
			UnlockedMarkers: []string{"channel4", "manifest"},
			SuccessOn2xx:    true,
			ForbiddenReason: ReasonGeoBlocked,
		})),
		target("bilibili-hk-mo", GroupHongKongTaiwan, bilibiliProbe(
			"https://api.bilibili.com/pgc/player/web/playurl?avid=473502608&cid=845838026&qn=0&type=&otype=json&ep_id=678506&fourk=1&fnver=0&fnval=16&module=bangumi",
		)),
		target("bilibili-tw", GroupHongKongTaiwan, bilibiliProbe(
			"https://api.bilibili.com/pgc/player/web/playurl?avid=50762638&cid=100279344&qn=0&type=&otype=json&ep_id=268176&fourk=1&fnver=0&fnval=16&module=bangumi",
		)),
		target("bahamut-anime", GroupHongKongTaiwan, bahamutProbe()),
		target("mytv-super", GroupHongKongTaiwan, jsonAllowedProbe(
			"https://www.mytvsuper.com/api/auth/getSession/self/",
			[]string{`"region":1`, `"country_code":"HK"`},
			[]string{`"region":0`, `"country_code":""`},
			"HK",
		)),
		target("viutv", GroupHongKongTaiwan, simpleProbe(probeRule{
			URL:             "https://viu.tv/",
			LockedMarkers:   []string{"GEO_CHECK_FAIL", "not available in your region"},
			UnlockedMarkers: []string{"viutv", "ViuTV"},
			PartialOn2xx:    true,
		})),
		target("abema", GroupJapan, jsonAllowedProbe(
			"https://api.abema.io/v1/ip/check?device=android",
			[]string{`"isoCountryCode":"JP"`, `"iso_country_code":"JP"`},
			[]string{"blocked_location", "anonymous_ip"},
			"JP",
		)),
		target("dmm-tv", GroupJapan, simpleProbe(probeRule{
			URL:             "https://tv.dmm.com/vod/",
			LockedMarkers:   []string{"FOREIGN", "海外からはご利用いただけません"},
			UnlockedMarkers: []string{"DMM TV", "dmmtv"},
			PartialOn2xx:    true,
		})),
		target("u-next", GroupJapan, simpleProbe(probeRule{
			URL:             "https://video.unext.jp/",
			LockedMarkers:   []string{"日本国外からはご利用いただけません", `"resultStatus":467`},
			UnlockedMarkers: []string{"U-NEXT", `"resultStatus":200`, `"resultStatus":475`},
			PartialOn2xx:    true,
		})),
		target("tver", GroupJapan, simpleProbe(probeRule{
			URL:             "https://tver.jp/",
			LockedMarkers:   []string{"日本国外では動画を視聴できません"},
			UnlockedMarkers: []string{"TVer", "platform_uid"},
			PartialOn2xx:    true,
		})),
		target("nhk-plus", GroupJapan, jsonCountryProbe(
			"https://location-plus.nhk.jp/geoip/area.json",
			"country_code",
			"JP",
		)),
		target("kocowa", GroupKorea, simpleProbe(probeRule{
			URL:             "https://www.kocowa.com/",
			LockedMarkers:   []string{"is not available in your region or country"},
			UnlockedMarkers: []string{"kocowa"},
			PartialOn2xx:    true,
		})),
		target("watcha", GroupKorea, simpleProbe(probeRule{
			URL:             "https://watcha.com/browse/theater",
			LockedMarkers:   []string{"not available in your region"},
			UnlockedMarkers: []string{"watcha", "/ko-KR/"},
			PartialOn2xx:    true,
			ForbiddenReason: ReasonVPNBlocked,
		})),
	}
}

func Registry() map[string]Target {
	catalog := Catalog()
	registry := make(map[string]Target, len(catalog))
	for _, target := range catalog {
		registry[target.ID] = target
	}
	return registry
}

func DefaultTargetIDs() []string {
	defaults := make([]string, 0, 21)
	for _, target := range Catalog() {
		if target.Group == GroupAI || target.Group == GroupGlobalMedia {
			defaults = append(defaults, target.ID)
		}
	}
	return defaults
}

func target(id string, group Group, probe Probe) Target {
	return Target{
		ID:    id,
		Group: group,
		Probe: probe,
	}
}
