package unlocktest

import (
	"slices"
	"testing"
)

func TestCatalogContainsExactlyThePlannedTargets(t *testing.T) {
	catalog := Catalog()
	if got, want := len(catalog), 36; got != want {
		t.Fatalf("catalog size = %d, want %d", got, want)
	}

	expected := []string{
		"chatgpt", "claude", "gemini", "copilot", "perplexity", "grok",
		"meta-ai", "sora", "deepseek",
		"netflix", "disney-plus", "youtube-premium", "prime-video", "max",
		"hulu", "paramount-plus", "peacock", "spotify", "tiktok", "dazn",
		"crunchyroll",
		"bbc-iplayer", "itvx", "channel-4",
		"bilibili-hk-mo", "bilibili-tw", "bahamut-anime", "mytv-super", "viutv",
		"abema", "dmm-tv", "u-next", "tver", "nhk-plus",
		"kocowa", "watcha",
	}

	seen := make(map[string]struct{}, len(catalog))
	for _, target := range catalog {
		if target.ID == "" {
			t.Fatal("catalog contains an empty id")
		}
		if target.Group == "" {
			t.Fatalf("%s has an empty group", target.ID)
		}
		if target.Probe == nil {
			t.Fatalf("%s has no probe", target.ID)
		}
		if _, exists := seen[target.ID]; exists {
			t.Fatalf("duplicate target id %q", target.ID)
		}
		seen[target.ID] = struct{}{}
	}

	for _, id := range expected {
		if _, ok := seen[id]; !ok {
			t.Errorf("missing planned target %q", id)
		}
	}
}

func TestDefaultTargetsAreAIAndGlobalMedia(t *testing.T) {
	defaults := DefaultTargetIDs()
	if got, want := len(defaults), 21; got != want {
		t.Fatalf("default target count = %d, want %d", got, want)
	}

	for _, target := range Catalog() {
		wantDefault := target.Group == GroupAI || target.Group == GroupGlobalMedia
		if slices.Contains(defaults, target.ID) != wantDefault {
			t.Errorf("%s default membership does not match group %s", target.ID, target.Group)
		}
	}
}
