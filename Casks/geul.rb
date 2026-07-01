cask "geul" do
  version "1.0.0"
  sha256 "a2f275fe813c396151b6d33b8d126bc7a18541300831a11a16fcca03f0ceaf9d"

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
