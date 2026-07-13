# Design QA

Final result: passed

## Evidence

- Chrome source: `/tmp/helium-dynamic-tabs.png` (official Helium dynamic-tabs reference)
- New-tab source: `/tmp/helium-ntp-comparison.png` (Helium is the browser on the left)
- iPad implementation: `/Users/orion/Documents/PHONE/helium-ios/Docs/ipad-new-tab.png`
- iPhone implementation: `/Users/orion/Documents/PHONE/helium-ios/Docs/iphone-new-tab.png`
- Full chrome comparison: `/tmp/helium-design-qa-full.png`
- Focused new-tab comparison: `/tmp/helium-design-qa-ntp.png`
- Viewports: iPad 2420 x 1668 landscape; iPhone 1206 x 2622 portrait
- State: fresh New Tab, light appearance

## Comparison history

- P0: the initial custom gradient, oversized Helium wordmark, search block, cards, and privacy copy did not match the sparse upstream page. Replaced them with the centered six-shortcut layout and edit control.
- P1: the initial mobile layout used a bottom address bar and a full-width iPad omnibox. Moved both platforms to the dynamic Helium two-row chrome and capped the centered omnibox width.
- P1: the initial custom bubble/globe marks did not match the product. Replaced them with the official Helium glyph, mark, and app icon assets.
- P2: the first comparison pass showed mismatched warm-white and tile colors, row heights, and a duplicate iPhone new-tab button. Corrected all four and recaptured both devices.
- P3 accepted platform differences: iOS status and safe-area regions, native system icon rendering, and responsive three-column shortcut wrapping on iPhone.

## Interaction checks

- Add shortcut opened its editor, accepted a name and URL, and added the shortcut to the grid.
- Shields opened the per-site panel and exposed the blocking controls.
- Back, forward, reload, address, bookmark, menu, new-tab, tab-title, and close-tab controls were present in the accessibility tree.
- Clean simulator build passed; 29 core tests passed.

No open P0, P1, or P2 visual issues remain in the tested state.
