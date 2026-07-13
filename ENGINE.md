# Browser engine plan

## Shipping lane: WebKit

The `Helium` target is a native SwiftUI shell around `WKWebView`. This is the supported global App Store lane and works on both iPhone and iPad. It also gives the app Safari's current engine security updates, passkeys, media stack, process isolation, Intelligent Tracking Prevention, and system accessibility integration.

The Shields layer uses WebKit content rules rather than pretending the app controls engine internals. Rules can block resource loads and cookies, hide page elements, upgrade known hosts to HTTPS, and exempt a site when the user lowers its shield.

## Research lane: un-Googled Blink

An alternative-engine build is a separate product, not a runtime switch:

1. Obtain Apple's regional Web Browser Engine Entitlement and Default Browser Entitlement.
2. Maintain a Chromium/Blink fork with Google service API keys and service integrations omitted.
3. Build a `BrowserEngineKit` host plus rendering, networking, and web-content extensions.
4. Meet Apple's WPT/Test262, memory-safety, sandbox, IPC, TLS, cookie-partitioning, vulnerability disclosure, and patch-time requirements.
5. Ship only in the approved region/platform combination with separate entitlement profiles.

Chromium's own iOS Blink instructions currently describe the build as experimental and intended for analysis, with Blink web tests limited to the simulator. It is therefore tracked as research rather than promised as a production option.

Official references:

- <https://developer.apple.com/app-store/review/guidelines/>
- <https://developer.apple.com/support/alternative-browser-engines/>
- <https://developer.apple.com/support/alternative-browser-engines-jp/>
- <https://developer.apple.com/documentation/browserenginekit>
- <https://chromium.googlesource.com/chromium/src/+/HEAD/docs/ios/build_instructions.md>
