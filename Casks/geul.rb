cask "geul" do
  version "1.0.0"
  sha256 "8958e76b14539ba484fabcafb1bbfb268bc482658bbcf00a2f4e9e63704824b2"

  url "https://github.com/iianjun/geul/releases/download/v#{version}/geul.dmg"
  name "geul"
  desc "Markdown viewer for CLI-first developers"
  homepage "https://github.com/iianjun/geul"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "geul.app"
  binary "#{appdir}/geul.app/Contents/Resources/Resources/ge", target: "ge"
  binary "#{appdir}/geul.app/Contents/Resources/Resources/ge", target: "geul"

  zap trash: [
    "~/.config/geul",
    "~/Library/Preferences/io.github.hasungjun.geul.plist",
  ]
end
