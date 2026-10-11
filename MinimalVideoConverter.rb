cask "minimal-video-converter" do
  version "1.1.1"
  sha256 "e7ce96f651d029917c7c935eafacc38123690ee64d8befb4729a166762f90a09"

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
