# Mumin Pro — canonical brand image

The only source image to replace is:

`assets/branding/mumin_pro_logo.png`

The source file is preserved unchanged. The asset preparation script removes
the connected magenta export canvas and writes a square transparent RGBA PNG to
`assets/branding/processed/mumin_pro_logo.png`. That processed image is shared
by the Android launcher, splash screen, and compact/expanded prayer notification.

The same script removes edge-connected white/black export backgrounds from the
five home shortcut illustrations and writes real RGBA PNG files into
`assets/images/home/reference_ui/processed/`. The original source images remain
untouched.

Requirements for a future replacement logo:
- Square PNG, 1024 × 1024 px or larger.
- Put the actual Mumin Pro mark in the center.
- Use transparent pixels outside the mark; do not include a magenta, black,
  white, or colored export canvas.
- Keep the lettering and crescent inside a generous launcher-safe margin.
- Do not include prayer names or countdown text.

The build pipeline runs `scripts/prepare_transparent_brand_assets.py` before
Flutter asset bundling and verifies actual transparent pixels. Android's tiny
status-bar glyph remains monochrome because Android requires that; the full
color logo is displayed inside the notification panel.

To replace the brand artwork in the future, replace only
`assets/branding/mumin_pro_logo.png` and run the same preparation script.
