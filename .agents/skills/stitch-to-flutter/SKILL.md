---
name: stitch-to-flutter
description: How to rebuild a Stitch screen in Flutter (tokens only, never paste exported HTML), then do the side-by-side visual QA.
---
# stitch-to-flutter

## When to use
When implementing a design from `screen_designs/` into Flutter code.

## Procedure
1. Open the HTML/PNG from `screen_designs/`.
2. Map the visual elements to tokens in `design_tokens.md` (colors, typography, spacing).
3. Write the Flutter code manually, using existing shared widgets where possible.
4. DO NOT copy or paste HTML/CSS.
5. Run the app and compare side-by-side with the PNG screenshot.

## Definition of Done
- Pixel-perfect match using theme tokens.
- Zero hardcoded colors or fonts.
