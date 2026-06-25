cask "geul" do
  version "1.0.0"
  sha256 "028d08bb7bc6b2bd33118d096291577498569120b948673090491e66ef596a0e"

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
