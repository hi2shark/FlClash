package main

import (
	"errors"
	"os"
	"path/filepath"
	"strings"

	"github.com/metacubex/mihomo/constant"
)

func isPathInsideHomeDir(path string) bool {
	homeDir := constant.Path.HomeDir()
	if homeDir == "" || path == "" {
		return false
	}
	absHome, err := filepath.Abs(homeDir)
	if err != nil {
		return false
	}
	absPath, err := filepath.Abs(path)
	if err != nil {
		return false
	}
	rel, err := filepath.Rel(absHome, absPath)
	if err != nil {
		return false
	}
	return rel != ".." && !strings.HasPrefix(rel, ".."+string(os.PathSeparator))
}

func providersDirForProfile(profileId string) (string, error) {
	if profileId == "" || strings.Contains(profileId, "..") || strings.ContainsAny(profileId, `/\`) {
		return "", errors.New("invalid profile id")
	}
	dir := filepath.Join(constant.Path.HomeDir(), "profiles", "providers", profileId)
	if !isPathInsideHomeDir(dir) {
		return "", errors.New("path is outside home dir")
	}
	return dir, nil
}
