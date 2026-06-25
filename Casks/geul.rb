cask "geul" do
  version "1.0.0"
  sha256 "c59dbc8d80d281bc1ef92b18893e98da6f0353cdf84729a9dc6bbbd2bbc91c21"

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
