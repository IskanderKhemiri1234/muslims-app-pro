# Mumin Pro — canonical brand image

The only source image to replace is:

`assets/branding/mumin_pro_logo.png`

The source file is preserved unchanged. The asset preparation script removes
the connected magenta export canvas and writes a square transparent RGBA PNG to
`assets/branding/processed/mumin_pro_logo.png`. The launcher artwork keeps a prominent scale with 12% transparent padding around
the original rounded-square tile. Its size is validated against an 83% upper
bound so future processing cannot shrink the logo excessively. The adaptive-icon
background uses a matching emerald-to-blue gradient to avoid a dark contrasting
frame around the tile. That processed image is shared by Android launcher surfaces, splash
screen, and compact/expanded prayer notification.

The same script removes edge-connected white/black export backgrounds from the
five home shortcut illustrations and writes real RGBA PNG files into
`assets/images/home/reference_ui/processed/`. The original source images remain
untouched.

Requirements for a future replacement logo:
- Square PNG, 1024 × 1024 px or larger.
- Put the actual Mumin Pro mark in the center.
- Use transparent pixels outside the mark; do not include a magenta, black,
  white, or colored export canvas.
- Preserve the original rounded-square tile and keep the wordmark prominent; the build script enforces a balanced 83% maximum artwork bound.
- Do not include prayer names or countdown text.

The build pipeline runs `scripts/prepare_transparent_brand_assets.py` before
Flutter asset bundling and verifies actual transparent pixels. Android's tiny
status-bar glyph remains monochrome because Android requires that; the full
color logo is displayed inside the notification panel.

To replace the brand artwork in the future, replace only
`assets/branding/mumin_pro_logo.png` and run the same preparation script.
