# Releasing Keymit

Keymit is distributed from GitHub as an ad-hoc signed universal macOS app.
The maintainer does not have an Apple Developer account, so releases cannot use
a Developer ID certificate or Apple notarization.

## Consequences

- The ad-hoc signature seals the app bundle and is verified during packaging,
  but it does not establish the publisher's identity with Apple.
- Gatekeeper will block the first normal launch after the app is downloaded.
- Users must explicitly approve Keymit in System Settings before opening it.
- Every release includes a SHA-256 file so users can verify the download against
  the checksum published on GitHub.

These limitations must be stated in every GitHub release description. Never
describe an ad-hoc build as Developer ID signed, notarized, or verified by Apple.

## Release checklist

1. Update and commit `CFBundleShortVersionString` and `CFBundleVersion` in
   `Info.plist`, together with the intended release changes.
2. Ensure the tracked working tree is clean.
3. Run:

   ```bash
   ./release.sh 1.0.0 1
   ```

4. Confirm that the script passes the tests, builds both arm64 and x86_64,
   verifies the ad-hoc app signature and DMG, and creates:

   - `dist/Keymit-<version>.dmg`
   - `dist/Keymit-<version>.dmg.sha256`

5. Verify the checksum locally, then create and push tag `v<version>`:

   ```bash
   shasum -a 256 -c dist/Keymit-1.0.0.dmg.sha256
   ```

6. Pushing the tag triggers `.github/workflows/release.yml`. It rebuilds and
   verifies the package, creates the GitHub Release, uses `INSTALL.md` as the
   release description, and attaches the DMG, checksum, and installation guide.

Pull requests targeting `main` run tests and the universal app build through
`.github/workflows/ci.yml`. Ordinary pushes to `main` do not trigger packaging;
`main` remains the stable archive line.

The build and release scripts contain only the ad-hoc signing path. Environment
variables from a maintainer's machine therefore cannot silently change the
published artifact into a differently signed package.
