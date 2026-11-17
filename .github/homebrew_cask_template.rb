cask "flclash" do
  version "VERSION"
  sha256 "ARM_SHA256"

  url "https://github.com/chen08209/FlClash/releases/download/v#{version}/FlClash-#{version}-macos-arm64.dmg"

  name "FlClash"
  desc "Multi-platform proxy client based on ClashMeta"
  homepage "https://github.com/chen08209/FlClash"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos
  depends_on arch: :arm64

  app "FlClash.app"

  postflight_steps do
    run "/usr/bin/xattr",
        args:           ["-rd", "com.apple.quarantine", "{{appdir}}/FlClash.app"],
        writable_paths: ["FlClash.app"],
        writable_base:  :appdir
  end

  uninstall quit: "com.hi2shark.flclash_nw"

  zap trash: [
    "~/Library/Application Support/com.hi2shark.flclash_nw",
    "~/Library/Caches/com.hi2shark.flclash_nw",
    "~/Library/Preferences/com.hi2shark.flclash_nw.plist",
    "~/Library/Saved Application State/com.hi2shark.flclash_nw.savedState",
  ]
end
