cask "minimal-video-converter" do
  version "1.0.0"
  sha256 "e6b4316d0ef6a74470e4cb9ebb41008186f86c73f49a69cd526d779c51552dbd"

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
