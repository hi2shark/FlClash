package main

import (
	"os"
	"path/filepath"
	"testing"

	C "github.com/metacubex/mihomo/constant"
)

func TestIsPathInsideHomeDir(t *testing.T) {
	homeDir := t.TempDir()
	previousHomeDir := C.Path.HomeDir()
	C.SetHomeDir(homeDir)
	t.Cleanup(func() {
		C.SetHomeDir(previousHomeDir)
	})

	inside := filepath.Join(homeDir, "profiles", "1.yaml")
	if !isPathInsideHomeDir(inside) {
		t.Fatalf("expected %s to be inside home dir", inside)
	}

	outside := filepath.Join(os.TempDir(), "flclash-outside")
	if isPathInsideHomeDir(outside) {
		t.Fatalf("expected %s to be outside home dir", outside)
	}

	escaped := filepath.Join(homeDir, "..", "etc", "passwd")
	if isPathInsideHomeDir(escaped) {
		t.Fatalf("expected escaped path to be rejected")
	}
}

func TestProvidersDirForProfile(t *testing.T) {
	homeDir := t.TempDir()
	previousHomeDir := C.Path.HomeDir()
	C.SetHomeDir(homeDir)
	t.Cleanup(func() {
		C.SetHomeDir(previousHomeDir)
	})

	dir, err := providersDirForProfile("42")
	if err != nil {
		t.Fatal(err)
	}
	expected := filepath.Join(homeDir, "profiles", "providers", "42")
	if dir != expected {
		t.Fatalf("got %s, want %s", dir, expected)
	}

	if _, err := providersDirForProfile("../etc"); err == nil {
		t.Fatal("expected invalid profile id")
	}
	if _, err := providersDirForProfile("a/b"); err == nil {
		t.Fatal("expected invalid profile id")
	}
	if _, err := providersDirForProfile(""); err == nil {
		t.Fatal("expected invalid profile id")
	}
}
