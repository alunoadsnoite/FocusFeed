# Current submission — 2026-10-26

Version **1.0.2**, ABI codes **4021 / 4022 / 4023**. The recipe pins
`d2c3b34d730e90426cd7ef184af07baa4d6b8a51` (tag `v1.0.2`).
[Pipeline #2987337391](https://gitlab.com/alunoadsnoite/fdroiddata/-/pipelines/2987337391)
passed all nine jobs, including the three ABI builds and APK checks.

The 32 Code Quality findings comprise three Minor SYSTEM_ALERT_WINDOW warnings
(one per ABI) and 29 informational findings: required permissions, R8 marker,
ABI/size, test-signed artifacts and Fastlane metadata. The overlay permission is
needed for the voluntary blocker; Usage Access reads local foreground events;
the foreground-service permissions maintain the user-started monitor;
notifications are optional; boot recovery restores paused progress without
crediting downtime. AndroidX generates the non-exported receiver permission.
The artifact links are for testing and do not establish official publication.
See [the report](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/52413/reports/code-quality).

Seven instrumented tests passed on a Motorola Edge 70 Fusion / Android 17
using the 1.0.2 debug APK and a separate overlay-compatible test target. The
two-launch test now waits for visible overlay behavior instead of Flutter's
idle event queue; an unselected-app scenario was added. This does not validate
the release APK's complete UI redemption flow or APKPure on Samsung.

Independent Samsung SM-G998B / Android 15 / APKPure retesting remains required:
two consecutive launches, unselected-app access, reward redemption and blocking
after expiry. The event overlap/activity-class fix has not established the
original device-specific cause. Maintainer acceptance remains pending.

# Abstract

### Please introduce the functions and usage of your app in summary, and also attach some screenshots.

FocusFeed (`io.github.alunoadsnoite.focusfeed`, MIT) is a Portuguese-language offline Pomodoro app for Android. Users select installed apps, grant Usage Access and draw-over-other-apps access, and start a focus session. Completed focus earns 20% of its duration as a break balance; spending that balance temporarily releases the selected apps. Pause, resume, stop, local daily history, recovery after interruption and optional notifications are included. Accessibility access is not required.

There is no account, backend, advertising, analytics or tracking. The release manifest has no INTERNET permission. Android Settings and other apps can intentionally hide overlays; background restrictions can interrupt monitoring. This is a voluntary focus aid, not an unbreakable parental-control app.

Real screenshots from a temporary Android 14 emulator (Portuguese UI; also provided as en-US fallback metadata):

![Home screen](https://raw.githubusercontent.com/alunoadsnoite/FocusFeed/635018efb6f288605f7e40a0464ef522762ca86e/fastlane/metadata/android/pt-BR/images/phoneScreenshots/1.png)

![Active focus session](https://raw.githubusercontent.com/alunoadsnoite/FocusFeed/635018efb6f288605f7e40a0464ef522762ca86e/fastlane/metadata/android/pt-BR/images/phoneScreenshots/2.png)

![Permissions and installed-app list](https://raw.githubusercontent.com/alunoadsnoite/FocusFeed/635018efb6f288605f7e40a0464ef522762ca86e/fastlane/metadata/android/pt-BR/images/phoneScreenshots/3.png)

![Visible blocker with zero balance](https://raw.githubusercontent.com/alunoadsnoite/FocusFeed/635018efb6f288605f7e40a0464ef522762ca86e/fastlane/metadata/android/pt-BR/images/phoneScreenshots/4.png)

The blocker screenshot was taken only after the instrumented test found the visible focus message above an overlay-compatible activity in a separate test APK. These are actual app screenshots, not mockups. Version 1.0.1 does not change the user interface from the version captured.

### Please elaborate why you wrote this app. Please highlight the unique functions it provides over other similar apps in F-Droid.

The aim is to connect focus time with a concrete, earned break allowance while keeping all progress on the device. The combination of a fixed 20% time balance, native app overlays, automatic reblocking after a break and recovery without crediting unmonitored time provides value beyond a standalone timer. We do not claim that individual features are absent from every other F-Droid app.

## Checklist

### Policy

* [x] The app complies with the [inclusion criteria](https://f-droid.org/docs/Inclusion_Policy).
* [x] The original app author has been notified (and does not oppose the inclusion). If you are not the author, please paste the link of the reply from the author.
* [x] The upstream app source code repo contains the app metadata in a [Fastlane](https://gitlab.com/snippets/1895688) or [Triple-T](https://gitlab.com/snippets/1901490) folder structure. The summary and description must be included and images, icon, and changelog should also be provided for better user experience. The `en-US` locale must be included.

### Docs

* [x] Please read [the guide](https://gitlab.com/fdroid/fdroiddata/-/blob/master/CONTRIBUTING.md) first if this is your first contribution.
* [x] Please make sure your metadata follows the best practice in [our templates](https://gitlab.com/fdroid/fdroiddata/tree/master/templates).
* [x] Please read the [Build Metadata Reference](https://f-droid.org/docs/Build_Metadata_Reference/) and make sure your metadata is valid.
* [x] Please read the [Quick Start Guide](https://f-droid.org/en/docs/Submitting_to_F-Droid_Quick_Start_Guide/).

### Merge Request Setup

* [x] The title of this merge request should follow "New app: app name" format.
* [x] Please make sure your fdroiddata fork is public and your branch is not protected. See <https://docs.gitlab.com/user/project/repository/branches/protected/>.
* [x] Please read [our Git guide](https://gitlab.com/fdroid/wiki/-/wikis/Tips-for-fdroiddata-contributors/Git-Usage) if you don't know how to rebase your branch. Don't rebase your branch if there is no conflict.
* [x] All related [fdroiddata](https://gitlab.com/fdroid/fdroiddata/issues) and [RFP issues](https://gitlab.com/fdroid/rfp/issues) have been referenced in this merge request
* [x] Please only submit one app in one MR.

### Metadata

* [x] Metadata must be put in `metadata/<applicationId>.yml`.
* [x] Metadata must be a valid YAML file.
* [x] Metadata must use LF as line ending.
* [x] Don't add summary/description/changelog/images or anything that should be provided in upstream repo. Please check the Changes tab to make sure there is no other unrelated files added in the MR.
* [x] Releases are tagged and auto update is enabled unless there is a special reason.
* [x] There is an issue tracker and contact info of the author so that we can report bugs and contact the author.
* [x] An AuthorName must be added. It doesn't need to be the real name.
* [ ] External repos are added as git submodules instead of srclibs. You can update git submodules without opening an MR in this repo and the submodule is covered by our scanner.
* [ ] Enable [Reproducible Builds](https://f-droid.org/docs/Reproducible_Builds). We'll use your signature for improved security/reliability, also allowing users to switch between different channels. Do note that if you don't enable reproducible build then the apk will be signed with our key so you can't enable it later. If you can't enable this, please add the reasons here.
* [x] Setup abi split if the APK is large and the splitted ones can be much smaller.
* [x] Only the latest versions should be kept in the metadata before it's merged. If you update the metadata, please replace the old versions with the new ones.
* [x] Don't add any disabled versions in the metadata.
* [x] The `commit` field should be the full hash. Please don't use tag or branch in commit.

### Pipeline

* [x] All pipelines should pass.
* [x] All warnings and errors in the Reports tab should be fixed or explained.
* [x] F-Droid CI runners are under GitLab's FOSS program, so there's no need for you to pay for any CI time. If Gitlab starts asking for phone numbers or credit cards don't submit anything, just leave a note in the MR so we know we need to trigger the CI.

## Explanations and validation

- **Author and related requests:** I am the upstream maintainer submitting this app through the same account. This MR is the existing FocusFeed submission; no separate FocusFeed RFP issue or duplicate MR was found in the project searches on 2026-10-14. The public fork uses the unprotected `focusfeed-metadata` branch.
- **Metadata:** only `metadata/io.github.alunoadsnoite.focusfeed.yml` belongs in this MR. Upstream Fastlane contains en-US and pt-BR summaries, descriptions, icons, changelogs and four real phone screenshots. The app UI is Portuguese; en-US provides English descriptions and the same actual screenshots.
- **Version and source:** version 1.0.2, source `d2c3b34d730e90426cd7ef184af07baa4d6b8a51` (tag `v1.0.2`), base 402 and ABI codes 4021/4022/4023. Auto updates use tags and `base * 10 + ABI`. Existing tags were not moved.
- **SDK source exception:** Flutter is a toolchain srclib, not an additional application source repository. The recipe follows the official `templates/build-flutter.yml` alternative: `flutter@stable`, then checkout the exact SDK revision recorded in `.metadata`. Other external source repositories are not used.
- **Signing exception:** upstream reproducible signing has not been verified and no reproducible upstream APK is published. Please use the F-Droid signing key. `FOCUSFEED_UNSIGNED=1` excludes the developer signing configuration. We understand that switching later to the upstream reproducible-signing arrangement is not available under the template's policy. No signing secrets are committed.
- **ABI splitting:** separate builds use `--split-per-abi --target-platform=...` and architecture-specific output paths. Local unsigned release sizes are approximately 14.3 MB (ARMv7), 17.0 MB (ARM64) and 18.4 MB (x86_64), compared with the previous ~47 MB universal APK. Flutter's release build already enables R8 and resource shrinking.
- **Local validation:** Flutter analyze passed, 20 Flutter tests and 13 JVM tests passed, all five instrumented Android 14 scenarios passed, and all three split release APKs compiled. The previous overlay test used Android Settings, which deliberately hides non-system overlays (`mForceHideNonSystemOverlayWindow=true`). It now uses a separate overlay-compatible test activity and still requires the actual visible focus message. Android's protections were not bypassed.
- **Permissions:** Usage Access checks only foreground-app events locally; SYSTEM_ALERT_WINDOW draws the voluntary blocker; foreground-service permissions maintain the user-started monitor; notifications are optional; BOOT_COMPLETED restores paused progress without awarding downtime credit. No QUERY_ALL_PACKAGES or accessibility service is declared. Launcher visibility is limited to apps returned by the launcher query.
- **Pipeline:** all nine jobs passed in https://gitlab.com/alunoadsnoite/fdroiddata/-/pipelines/2987337391 on the submitted recipe. The 32 Reports findings are explained above. Independent Samsung testing and maintainer acceptance remain pending.
- **Platform scope:** this submission builds Android; `rm: ios` excludes iOS source. iPhone Screen Time validation remains pending upstream and is not claimed as Android build validation.
