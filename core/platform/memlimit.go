package platform

import (
	"strconv"
	"strings"
)

const (
	defaultGoMemoryLimit = 256 << 20
	minGoMemoryLimit     = 192 << 20
	maxGoMemoryLimit     = 448 << 20
)

func computeMemoryLimit(memTotalBytes int64) int64 {
	if memTotalBytes <= 0 {
		return defaultGoMemoryLimit
	}
	target := memTotalBytes / 10
	return max(minGoMemoryLimit, min(maxGoMemoryLimit, target))
}

func parseMemTotalBytes(content string) int64 {
	for line := range strings.SplitSeq(content, "\n") {
		rest, ok := strings.CutPrefix(line, "MemTotal:")
		if !ok {
			continue
		}
		fields := strings.Fields(rest)
		if len(fields) == 0 {
			return 0
		}
		kb, err := strconv.ParseInt(fields[0], 10, 64)
		if err != nil || kb <= 0 {
			return 0
		}
		if kb > (1<<62)/1024 {
			return maxGoMemoryLimit * 10
		}
		return kb * 1024
	}
	return 0
}
