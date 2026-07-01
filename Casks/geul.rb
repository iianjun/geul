cask "geul" do
  version "1.0.0"
  sha256 "14f74c6b7a02d529fa5b9cdb41a890e51d75e1ccc98acd43723f949ef3e1533a"

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
