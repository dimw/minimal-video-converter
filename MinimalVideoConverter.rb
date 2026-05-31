cask "minimal-video-converter" do
  version "1.0.0"
  sha256 "c27a8b75722ef0199ee54743c2116ce93fcf51ae78baa132d86c73c0c34bf5bd"

  url "https://github.com/dimw/minimal-video-converter/releases/download/v#{version}/MinimalVideoConverter.tar.gz"
  name "MinimalVideoConverter"
  desc "Minimal video converter app for macOS"
  homepage "https://github.com/dimw/minimal-video-converter"

  depends_on formula: "ffmpeg"
  depends_on macos: ">= :ventura"

  app "MinimalVideoConverter.app"

  caveats <<~EOS
    MinimalVideoConverter requires FFmpeg, which has been installed via Homebrew.
    FFmpeg is expected at: #{HOMEBREW_PREFIX}/bin/ffmpeg
  EOS
end
