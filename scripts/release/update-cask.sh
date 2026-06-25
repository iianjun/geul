#!/bin/bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ensure_project_root

if [[ ! -f "$DMG_PATH" ]]; then
    echo "error: missing notarized artifact at $DMG_PATH" >&2
    exit 1
fi

sha256="$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
mkdir -p Casks

cat > Casks/geul.rb <<RUBY
cask "geul" do
  version "$VERSION"
  sha256 "$sha256"

  url "https://github.com/hasungjun/geul/releases/download/v#{version}/geul-#{version}.dmg"
  name "geul"
  desc "Markdown viewer for CLI-first developers"
  homepage "https://github.com/hasungjun/geul"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "geul.app"
  binary "#{appdir}/geul.app/Contents/Resources/Resources/ge", target: "ge"
  binary "#{appdir}/geul.app/Contents/Resources/Resources/ge", target: "geul"

  zap trash: [
    "~/.config/geul",
    "~/Library/Preferences/io.github.hasungjun.geul.plist",
  ]
end
RUBY

echo "Updated Casks/geul.rb for geul $VERSION"
