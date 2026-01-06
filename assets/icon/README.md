# Icon Generation (Android / Flutter)

We generate Android launcher icons from our SVG logo using Inkscape +
[`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons).

## Requirements

- Inkscape (CLI available as `inkscape`)
- Flutter/Dart (to run `flutter_launcher_icons`)

## Adaptive Icon Foreground (Transparent PNG)

Our mark needs extra padding and a slight vertical translation to look optically
centered inside Android's masked icon shapes (e.g., circle). The command below
exports a 1024px adaptive icon foreground layer on a transparent background,
forcing the mark to white.

```bash
inkscape assets/logo/whatchord_logo.svg \
  --batch-process \
  --actions="select-all;transform-scale:0.70,0.70;transform-translate:0,15;object-set-attribute:fill,#ffffff" \
  --export-type=png \
  --export-width=1024 \
  --export-filename=assets/icon/foreground.png
```

Notes:

- If using the square icon variant, we typically use `transform-scale:0.80,0.80`
  and no translation.

## Generate Platform Icon Assets

After updating `assets/icon/foreground.png`, regenerate the launcher icon
assets:

```bash
dart run flutter_launcher_icons
```

## Asset Optimization (Optional)

Before committing SVG or PNG assets, we typically run them through lightweight
manual optimization tools to reduce file size:

- SVGs: https://svgomg.net/
- PNGs: https://squoosh.app/

This is not required to regenerate icons correctly, but helps keep the
repository lean and avoids committing unnecessarily large binary assets.
