Packaging your SwiftUI app for installation via **Homebrew** is a great way to distribute it — especially for developers and CLI-savvy users. Let’s walk through how to make it installable and also include **`ffmpeg` as a prerequisite**.

---

## ✅ 1. Build your SwiftUI app into a `.app` bundle

Use Xcode or CLI to archive and export the release version of your app.

### With CLI:
```bash
xcodebuild -scheme MinimalVideoConverter -configuration Release -derivedDataPath build
```

Find the `.app` here:
```
build/Build/Products/Release/MinimalVideoConverter.app
```

Then, package it in a `.tar.gz`:
```bash
tar -czf MinimalVideoConverter.tar.gz -C build/Build/Products/Release MinimalVideoConverter.app
```

Upload this somewhere publicly accessible (GitHub Releases is perfect).

---

## ✅ 2. Create a Homebrew Tap (formula)

You’ll write a custom Homebrew formula (Ruby file) that:

- Downloads the `.tar.gz`
- Installs the `.app` into `/Applications`
- Declares `ffmpeg` as a dependency

### Example formula: `yourapp.rb`

```ruby
class Yourapp < Formula
  desc "MinimalVideoConverter – A SwiftUI app that converts videos"
  homepage "https://github.com/dimw/minimal-video-converter"
  url "https://github.com/dimw/minimal-video-converter/releases/download/v1.0.0/YourAppName.tar.gz"
  sha256 "INSERT_SHA256_OF_TAR_FILE"
  license "MIT"

  depends_on "ffmpeg"

  def install
    prefix.install Dir["MinimalVideoConverter.app"]
    # Optional: link to /Applications
    system "cp", "-r", "#{prefix}/MinimalVideoConverter.app", "/Applications/"
  end

  def caveats
    <<~EOS
      MinimalVideoConverter has been installed to /Applications.
      Make sure FFmpeg is accessible at /opt/homebrew/bin/ffmpeg.
    EOS
  end
end
```

To get the `sha256`:
```bash
shasum -a 256 MinimalVideoConverter.tar.gz
```

---

## ✅ 3. Create your own Tap

On GitHub, make a repo like:
```
yourusername/homebrew-yourapp
```

Put your formula inside: `Formula/yourapp.rb`

Then users can install it like:

```bash
brew tap yourusername/yourapp
brew install yourapp
```

Or even simpler if they haven’t tapped yet:

```bash
brew install yourusername/yourapp/yourapp
```

---

## ✅ 4. Test locally (before publishing)

```bash
brew install --build-from-source ./yourapp.rb
```
