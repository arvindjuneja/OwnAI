# Privacy Policy for Vays

**Last Updated:** 2026-04-29

## 1. Introduction

This Privacy Policy describes how Vays ("the App") handles your data on
both the **Vays iOS app** and the **Vays macOS app**. Vays is built by a
solo developer (Arvind Juneja, contact: arvind@oumm.pl) with privacy as
the default. This policy is written to be specific about what happens
on each platform; please read the section that applies to you.

The same policy applies to the legacy "OwnAI" macOS app, which has been
rebranded to Vays. Existing OwnAI users have continued to receive Vays
as a free update.

## 2. Summary

- **No account required.** The App has no login, no user accounts, and
  no server-side state managed by the developer.
- **No analytics, no advertising, no tracking SDKs** of any kind.
- **No data collected by the developer.** Recordings, transcripts,
  conversations, settings, and API keys never reach servers we control.
- **All AI runs on-device by default.** Cloud AI is opt-in, available
  only on macOS, and only when the user enters their own API key.

## 3. Data the App Handles, by Platform

### 3.1 Vays for iPhone & iPad

**On-device, never leaves the device:**
- Audio recordings (microphone capture, stored in app sandbox)
- Transcripts (produced on-device by Apple Neural Engine via Parakeet
  TDT v3 or, optionally, WhisperKit)
- AI chat conversations (produced on-device by Gemma 3 E2B, downloaded
  once from Hugging Face / Apple CDN as read-only model weights)
- Custom vocabulary, processing preferences, and other settings

**Network destinations the iOS app may reach (all opt-in, none of them
third-party AI services):**

1. **Apple iCloud Key-Value Store** — off by default. When the user
   enables iCloud Sync (Settings → Sync), the App syncs only:
   - Custom vocabulary terms
   - Non-secret processing preferences
   It uses Apple's `NSUbiquitousKeyValueStore`, which is encrypted at
   rest with the user's Apple ID and never reaches our infrastructure.
   **Audio, transcripts, conversations, API keys, and saved server
   hosts are never sent to iCloud.**

2. **The user's own Mac on the local network** — off by default,
   requires the user to explicitly pair the iOS app with the Vays Mac
   app (entering a 6-digit code displayed on the Mac). After pairing,
   the two devices discover each other via Bonjour (`_vays._tcp`) and
   exchange memos and transcripts directly over the local network.
   No third-party server is involved.

3. **Optional Ollama provider** — only available when paired with the
   user's own Mac running Ollama. When the user explicitly selects
   Ollama as the chat provider in the iOS chat picker, chat messages
   travel over the local network to the Ollama instance running on the
   user's Mac. Ollama itself runs entirely on-device on the user's Mac;
   no cloud component is involved.

4. **One-time read-only model downloads** — on first use, the App
   downloads on-device AI model weights (Gemma 3 E2B and, optionally,
   WhisperKit models) from Hugging Face / Apple CDNs over standard
   HTTPS. These are read-only file transfers; no user content is
   uploaded.

**The iOS app does not send user data to any third-party AI service.**
There is no UI on iOS for entering an OpenAI (or any cloud AI provider)
API key. OpenAI integration is exclusive to the macOS companion app
(see Section 3.2).

### 3.2 Vays for Mac

The Mac app's default behavior is on-device, identical to iOS in
spirit: transcription via WhisperKit / Parakeet on Apple Neural Engine,
AI chat via locally-running Gemma. In addition, the Mac app offers
**optional integrations with cloud and local AI services that the user
must explicitly enable**:

1. **OpenAI (cloud, optional, requires user's own API key).** The Mac
   user can enter their own OpenAI API key in Settings → Chat. When the
   OpenAI provider is selected from the chat picker, the App sends the
   user's chat messages — and any explicitly attached note text — to
   OpenAI's API endpoint (`api.openai.com`) over HTTPS. The API key is
   stored locally in the user's preferences and is never transmitted to
   our infrastructure or to iCloud.

   **What is sent to OpenAI**: chat messages, attached note text (only
   if the user attaches a note), and the system prompt. **What is not
   sent**: audio, transcripts other than text the user has chosen to
   include, settings, or anything else about the user's account or
   device.

   **Who the data goes to**: OpenAI, L.L.C. The data handling, retention,
   and use practices of OpenAI are governed by **OpenAI's own privacy
   policy** at https://openai.com/policies/privacy-policy. OpenAI is a
   third-party service we do not control. Per OpenAI's own published
   policy at the time of writing, API requests are not used for model
   training by default. The user is encouraged to review OpenAI's
   policy before enabling this provider.

2. **Ollama (local, optional, user's own server).** The Mac user can
   point the App at any Ollama instance reachable on the local network
   or via a custom URL. When Ollama is selected, chat messages travel
   to the Ollama URL the user specified. The user is responsible for
   the privacy of the Ollama instance they connect to.

3. **Apple iCloud Key-Value Store** — same as iOS. Off by default;
   syncs only vocabulary and non-secret preferences when enabled.

4. **Cross-device pairing with iOS** — same Bonjour mechanism as
   described in Section 3.1, from the Mac side.

5. **Accessibility framework usage** — the Mac app's "Voice Input
   Assistance" (Dictate Mode) feature uses the macOS Accessibility
   framework (`AXIsProcessTrustedWithOptions` and
   `CGEventKeyboardSetUnicodeString`) to insert dictated text into the
   focused field of the active app, after the user has explicitly
   granted Accessibility permission via System Settings. The
   Accessibility framework is used only for this assistive-input
   purpose and only after explicit user consent. **No data is
   exfiltrated; no contents of other apps' fields are read.**

## 4. Permissions Requested

### iOS

- **Microphone** — for recording voice memos and Quick Tasks. Audio is
  used only on-device for recording and transcription.
- **Speech Recognition** (optional, only if the user enables Apple's
  on-device live transcription) — used for real-time live transcription
  via Apple's `SFSpeechRecognizer`. We configure the recognizer to
  prefer on-device recognition where supported.
- **Local Network** — for Bonjour discovery of the user's own Mac
  during pairing.
- **Reminders** (optional, requested only if the user uses the "Save
  Quick Task to Reminders" feature).
- **Photos** (optional, requested only if the user attaches an image
  to a chat message).

### macOS

- **Microphone** — for recording voice memos.
- **Speech Recognition** (optional, see iOS).
- **Local Network** — for Bonjour discovery of paired iOS devices.
- **Calendars** (optional, requested only when the user attempts to
  read calendar context).
- **Accessibility** (optional, requested when the user enables Voice
  Input Assistance / Dictate Mode). Used solely to insert dictated
  text into the focused text field of the active app.

## 5. Data Sharing and Disclosure

The developer does not share any user data with third parties. The
only outbound network destinations from the App are listed in
Section 3, and each is either:

- The user's own infrastructure (their Mac, their Ollama server, their
  iCloud Key-Value Store), or
- Apple-operated infrastructure with a documented privacy posture
  (iCloud KVS, Apple Speech Recognition, Apple/Hugging Face model
  CDNs), or
- A cloud provider the user has explicitly configured with their own
  API key (OpenAI, on macOS only).

The developer has no business relationship with OpenAI; the user
contracts directly with OpenAI when they enter their own API key. The
developer does not receive any data the user sends to OpenAI.

## 6. Data Retention and Deletion

All recordings, transcripts, conversations, and settings are stored
locally on the user's device(s) and remain there until the user
deletes them or uninstalls the App. Deleting the App removes all
locally stored data. Disabling iCloud Sync stops further syncs but
does not, by itself, remove already-synced vocabulary or preferences
from iCloud — the user can clear those via Apple's iCloud management.

We do not retain any user data, because we do not collect any.

## 7. Children's Privacy

The App is rated 4+ and contains no objectionable content. It is not
directed to children, and we do not knowingly collect any personal
information from anyone, including children. If a parent or guardian
believes information has been provided in error, please contact us.

## 8. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Material changes
will be reflected in the "Last Updated" date at the top of this
policy. We may also notify users via in-app messaging or App Store
release notes for substantive changes.

## 9. Contact

Questions about this Privacy Policy can be sent to:

**arvind@oumm.pl**

Arvind Juneja, sole developer of Vays.
