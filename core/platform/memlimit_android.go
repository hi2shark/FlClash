//go:build android

package platform

import (
	"os"
	"runtime/debug"
	"sync"

	"github.com/metacubex/mihomo/log"
)

var configureMemoryLimitOnce sync.Once

func ConfigureMemoryLimit() {
	configureMemoryLimitOnce.Do(func() {
		if os.Getenv("GOMEMLIMIT") != "" {
			return
		}
		data, _ := os.ReadFile("/proc/meminfo")
		limit := computeMemoryLimit(parseMemTotalBytes(string(data)))
		debug.SetMemoryLimit(limit)
		log.Infoln("[APP] Go soft memory limit set to %d MiB", limit>>20)
	})
}
