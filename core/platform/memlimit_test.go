package platform

import "testing"

func TestParseMemTotalBytesReadsProcMeminfoKilobytes(t *testing.T) {
	const sample = "MemFree:          512000 kB\nMemTotal:        8388608 kB\nBuffers:           12345 kB\n"
	got := parseMemTotalBytes(sample)
	want := int64(8388608) * 1024
	if got != want {
		t.Fatalf("parseMemTotalBytes = %d, want %d", got, want)
	}
}

func TestParseMemTotalBytesRejectsMalformedInput(t *testing.T) {
	for _, sample := range []string{
		"",
		"MemTotal:\n",
		"MemTotal: invalid kB\n",
		"MemTotal: -100 kB\n",
		"MemAvailable: 1024 kB\n",
	} {
		if got := parseMemTotalBytes(sample); got != 0 {
			t.Errorf("parseMemTotalBytes(%q) = %d, want 0", sample, got)
		}
	}
}

func TestComputeMemoryLimitClampsToAndroidBudget(t *testing.T) {
	cases := []struct {
		memTotal int64
		want     int64
	}{
		{0, defaultGoMemoryLimit},
		{-1, defaultGoMemoryLimit},
		{1 << 30, minGoMemoryLimit},
		{4 << 30, (4 << 30) / 10},
		{12 << 30, maxGoMemoryLimit},
	}
	for _, tc := range cases {
		if got := computeMemoryLimit(tc.memTotal); got != tc.want {
			t.Errorf("computeMemoryLimit(%d) = %d, want %d", tc.memTotal, got, tc.want)
		}
	}
}
