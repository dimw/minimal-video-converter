# How to release

Releases are automated via GitHub Actions. Pushing a version tag triggers the pipeline, which builds the app, packages it, creates a GitHub Release, and updates the Homebrew cask.

## Steps

1. Make sure all changes are committed and pushed to `main`.

2. Tag the release:

   ```bash
   git tag v1.2.3
   git push origin v1.2.3
   ```

   The tag must start with `v` and follow semver (e.g. `v1.2.3`).

3. The [release workflow](.github/workflows/release.yml) will:
   - Install ffmpeg on the build runner
   - Build `MinimalVideoConverter.app` in Release configuration (unsigned)
   - Package it as `MinimalVideoConverter.tar.gz`
   - Compute the SHA-256 of the archive
   - Update `version` and `sha256` in [`MinimalVideoConverter.rb`](MinimalVideoConverter.rb)
   - Create a GitHub Release with the archive attached
   - Commit the updated cask back to `main`

4. Once the workflow completes, users can install or upgrade via:

   ```bash
   brew tap dimw/minimal-video-converter
   brew install --cask minimal-video-converter
   ```

   Or, if already installed:

   ```bash
   brew upgrade --cask minimal-video-converter
   ```

## Cask tap repository

The cask formula lives in this repo (`MinimalVideoConverter.rb`). Homebrew resolves the tap as `dimw/minimal-video-converter` because the GitHub repo is named `minimal-video-converter` (Homebrew strips the `homebrew-` prefix convention — here the repo name itself serves as the tap name).

## Manual release (fallback)

If the workflow fails, you can release manually:

```bash
# Build
xcodebuild -scheme MinimalVideoConverter -configuration Release -derivedDataPath build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Package
tar -czf MinimalVideoConverter.tar.gz -C build/Build/Products/Release MinimalVideoConverter.app

# Get SHA-256
shasum -a 256 MinimalVideoConverter.tar.gz
```

Then update `MinimalVideoConverter.rb` with the new `version` and `sha256`, upload the `.tar.gz` to the GitHub Release, and commit the cask change to `main`.
