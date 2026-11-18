# Chess Coach — Windows / GitHub Actions ReplayKit diagnostic

This is an **unsigned iOS build source project**, not an already-tested IPA.
It has the app target + embedded Broadcast Upload Extension.
It is designed as a minimal **installation / legacy-API diagnostic** for your own permitted practice sessions.
It contains no chess engine and provides no engine help against human opponents.

## Important iOS 27 warning
Apple now documents ScreenCaptureKit as the replacement for ReplayKit screen streaming.
ReplayKit `RPBroadcastSampleHandler` is documented as deprecated / no longer supported.
On iOS 27.2, this old extension **may compile but not function**, even if correctly installed.
A working compiler build does NOT prove device support.

## GitHub steps (Windows)
1. Create a new **Public** GitHub repository (e.g. `ChessCoach-ReplayKit-Test`). Never upload Apple ID passwords or provisioning credentials.
2. Extract this ZIP on Windows. In the GitHub repository choose **Add file -> Upload files** and upload the **contents** of the extracted folder, including the hidden `.github/workflows/build-ios.yml` directory. If the web uploader ignores `.github`, create the workflow directly using `Add file -> Create new file` and name it `.github/workflows/build-ios.yml`, pasting the workflow content.
3. In **Actions**, choose **Build unsigned Chess Coach IPA** and **Run workflow** (or let the push trigger it).
4. Open the completed run -> **Artifacts** -> download `ChessCoach-unsigned-IPA` ZIP -> extract `ChessCoach-unsigned.ipa`.
5. Check the GitHub build log for `BroadcastExtension.appex`. Without it, do not attempt installation.

## Windows sideload test
1. Connect iPhone via USB, unlock, press **Trust** when prompted.
2. Open Sideloadly, choose device and select the `.ipa`.
3. Choose **Apple ID Sideload** with a free Apple account. **Do not remove App Extensions / PlugIns**.
4. Install. If instructed, enable Developer Mode and restart: Settings -> Privacy & Security -> Developer Mode. Trust the developer profile if iOS requests it.
5. Open Chess Coach. Tap the broadcast picker. Check whether "Chess Coach Broadcast" appears. If it doesn't, stop and collect the Sideloadly log.
6. If it appears, try starting the broadcast and switching to a permitted practice app. This initial prototype only counts frames in extension sandbox; it does NOT expose the count in the main app. Picker visibility and launch are the initial test, NOT proof of correct streaming.

## Signing caveats
Sideloadly can re-sign a free-account IPA, but nested extension bundle IDs/profiles can fail.
Try its default signing mode first, without changing app bundle identifiers or stripping plugins.
A free Apple ID installation typically expires after seven days.
This prototype deliberately does **not** use App Groups to avoid a second entitlement hurdle in the first installation test.
A later shared App Group test would require both targets to be provisioned appropriately and is NOT guaranteed with free-account re-signing.

## Security
GitHub repository must be public for GitHub-hosted runners at no cost. Do not upload private data, screenshots, secrets, or Apple credentials.
The diagnostic extension writes only a frame count into its own local sandbox and does not transmit screen contents.

## If compiling fails
The GitHub build log is authoritative. Paste the FIRST Swift compiler error, XcodeGen error, or signing error. Code was not compiled in this environment because Xcode is not available here.
