# Design QA

final result: passed

## Visual truth and implementation evidence

- Source new tab: `/Users/orion/Documents/PHONE/helium-ios/Docs/References/helium-macos-new-tab-dark.jpeg`
- Source collapsed tabs: `/Users/orion/Documents/PHONE/helium-ios/Docs/References/helium-macos-tabs-collapsed-dark.jpeg`
- Source settings: `/Users/orion/Documents/PHONE/helium-ios/Docs/References/helium-macos-settings-dark.jpeg`
- Source blocker: `/Users/orion/Documents/PHONE/helium-ios/Docs/References/helium-macos-shield-panel-dark.jpeg`
- iPad new tab: `/Users/orion/Documents/PHONE/helium-ios/Docs/ipad-new-tab.png`
- iPhone new tab: `/Users/orion/Documents/PHONE/helium-ios/Docs/iphone-new-tab.png`
- iPad settings: `/Users/orion/Documents/PHONE/helium-ios/Docs/ipad-settings.png`
- iPad Shields: `/Users/orion/Documents/PHONE/helium-ios/Docs/ipad-shields.png`
- Full-view comparisons: `Docs/QA/newtab-comparison.png`, `Docs/QA/settings-comparison.png`, and `Docs/QA/shields-comparison.png`
- Focused chrome comparison: `Docs/QA/chrome-comparison.png`
- Source viewport: 1001 x 768 desktop Helium capture, dark appearance
- Implementation viewports: 2420 x 1668 iPad landscape and 1206 x 2622 iPhone portrait, dark appearance
- States: fresh New Tab; expanded and collapsed vertical tabs; Appearance settings; collapsed Shields panel

## Findings

No actionable P0, P1, or P2 differences remain in the captured states.

The required fidelity surfaces were checked:

- Fonts and typography: system sans matches Chromium/Roboto closely at the measured 12–14 point chrome and settings sizes. Weights, truncation, and the long bookmarks-bar selection were corrected and recaptured.
- Spacing and layout rhythm: the 166-point expanded rail, 35-point collapsed rail, compact toolbar, rounded content frame, centered shortcut, settings category rail, and dense settings rows track the source proportions.
- Colors and tokens: the implementation uses the measured `#2B2B2B` chrome, `#4D4D4D` new-tab canvas, `#303134` settings cards, muted salmon focus stroke, periwinkle rail accent, and blue blocker power state.
- Image and icon fidelity: the official Helium glyph and app mark remain source assets. Standard controls use SF Symbols rather than drawn approximations; no placeholder art remains.
- Copy and content: New Tab, Add shortcut, settings categories and controls, blocker labels, counts, More, and Less match the captured Helium states.

Accepted P3 platform differences are the iOS status/safe-area region, absence of macOS traffic-light controls, native switch rendering and larger touch hit areas, and the iPhone slide-out tab drawer. The desktop source omnibox was focused during capture while the implementation New Tab evidence shows its resting state; the implementation has the measured salmon outline when focused.

## Comparison history

- P0: the previous port used a light horizontal-tab UI. Replaced it with the user's actual dark vertical-tab Helium shell and forced the captured dark appearance.
- P0: the previous New Tab seeded five shortcuts. Removed them so a fresh profile contains only the centered Add shortcut control.
- P1: vertical-tab expansion, collapse, and compact-device behavior were missing. Added a persistent wide-iPad rail, 35-point compact rail, and leading iPhone/iPad overlay drawer.
- P1: settings and privacy controls were native light Forms. Rebuilt settings as an in-browser `helium://settings` surface and Shields as the measured blocker card.
- P2: settings copy and the bookmarks-bar value differed and wrapped. Matched the source copy and forced the selection onto one line, then recaptured the settings state.
- P2: the first Shields sheet clipped the More/Less footer. Increased the default detent to 430 points and recaptured the complete panel.

## Interaction and build checks

- `HeliumUITests.testVerticalTabsAndNewTabShell` passed: expanded rail, New Tab, Add shortcut, Shields, and menu controls were present.
- `HeliumUITests.testSettingsSurface` passed: the Helium menu opened the embedded settings route and exposed the search field and Appearance category.
- `HeliumUITests.testShieldsPanel` passed: the panel opened and exposed statistics and protection details.
- Clean iOS Simulator build passed.
- All 29 HeliumCore tests passed.
- Browser-console checks are not applicable to this native SwiftUI/WKWebView shell; build and XCTest logs contain no application errors.
