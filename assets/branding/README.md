# Mumin Pro — canonical brand image

Place the final square Mumin Pro logo here:

`assets/branding/mumin_pro_logo.png`

Requirements:
- PNG, exactly square; 1024 × 1024 px recommended.
- Transparent background is preferred so the logo adapts cleanly to the launcher mask and notification card.
- Keep the main mark centered with generous safe padding (about 15% on every edge).
- Do not include prayer names, countdown text, or other changing text in the image.

This is the single canonical image source. Flutter reads it through
`MuminBrandAssets.logo`. Android copies it during the Gradle pre-build step
to its native drawable resources for the launcher and persistent countdown
notification. Replacing this one file updates those image surfaces on the next
build. Android's tiny status-bar notification glyph remains a separate
monochrome system icon, as required by Android.

Do not rename the file; replace its contents to change the brand artwork.
