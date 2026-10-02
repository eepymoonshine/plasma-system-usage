# System Usage plasmoid

KDE Plasma 6 panel widget (`org.kde.plasma.systemusage`) showing CPU, RAM and GPU usage. It is visually modelled on the Claude Usage plasmoid (`~/.local/share/plasma/plasmoids/org.kde.plasma.claudeusage/`); when adding UI, copy that widget's patterns (cards, section titles, rings, chips) rather than inventing new ones.

## Layout

```
package/                  the Plasma package (metadata.json + contents/)
  contents/config/main.xml        config schema (kcfg)
  contents/config/config.qml      config page list
  contents/ui/main.qml            PlasmoidItem: sensors, derived values, history, helpers
  contents/ui/CompactView.qml     panel representation (ring / bar / text styles)
  contents/ui/FullView.qml        popup representation (cards)
  contents/ui/UsageRing.qml       progress ring with centered number
  contents/ui/TrendChart.qml      multi-series sparkline (Canvas)
  contents/ui/configGeneral.qml   settings page
```

`CompactView` and `FullView` reach into `main.qml` through `root.*` and the sensor ids defined there (e.g. `cpuFreq`, `vramUsed`). This works through QML context inheritance; keep new shared state in `main.qml`.

## Dev loop

The installed widget is a symlink to this repo:
`~/.local/share/plasma/plasmoids/org.kde.plasma.systemusage -> ~/Git/plasma-system-usage/package`

- After editing, reload the panel with `plasmashell --replace &`. The user usually runs this themselves.
- Do **not** run `kpackagetool6 -u package`; it replaces the symlink with a copy.
- Test standalone with `plasmawindowed org.kde.plasma.systemusage` (shows the popup view, since `preferredRepresentation` is not forced). QML errors print to stderr.
- Screenshot the focused window with `spectacle -b -n -a -o <file>`. The new window does not always get focus, so this can capture the wrong window.
- Lint with `qmllint --bare -I /usr/lib/qt6/qml <file>`. It cannot resolve the cross-file `root.*` references, so ignore those warnings.

## Data sources

All live values come from the `ksystemstats` daemon via `org.kde.ksysguard.sensors` (`Sensors.Sensor { sensorId: ...; updateRateLimit: ... }`). List available sensor ids with:

```sh
busctl --user call org.kde.ksystemstats1 /org/kde/ksystemstats1 org.kde.ksystemstats1 allSensors
busctl --user call org.kde.ksystemstats1 /org/kde/ksystemstats1 org.kde.ksystemstats1 sensorData as 1 cpu/all/usage
```

Known quirks:
- `cpu/all/name` returns the literal `"All"`, so the CPU model is read once from `/proc/cpuinfo` with a `Plasma5Support.DataSource` (`engine: "executable"`).
- `cpu/all/cpuCount` is the socket count (1); use `cpu/all/coreCount` for threads.
- GPU clock flips between 0 and a real value about every second when idle; GPU power may be unavailable. `DetailRow` stays hidden until its value is first non-empty, then stays visible (showing `fallback` when it drops back to 0) so the popup never resizes while open.
- `formattedValue` contains a narrow no-break space (U+202F) and a zero-width space (U+200B), e.g. `"500\u202FM\u200BHz"`. Fonts without U+202F render it through a taller fallback font, so rows jump 2px. Always go through `root.fmt(sensor)`, which normalizes them.
- Use `root.ready(sensor)` before showing a value; GPU cards are hidden when `gpu/all/usage` is not ready.

Per-core usage uses one `Sensors.Sensor` per logical CPU (`cpu/cpuN/usage`), created by an `Instantiator` in `main.qml` sized from `cpu/all/coreCount`. The history `Timer` copies their values into `root.coreUsages`; the Cores card's `Repeater` uses the count as its model so bars persist and animate instead of being recreated.

Launch external programs through the `launcher` DataSource in `main.qml` (e.g. `kstart plasma-systemmonitor`), not `Qt.openUrlExternally` on a `.desktop` file.

## Conventions

- Sizes and spacing come from `Kirigami.Units` and colors from `Kirigami.Theme`; usage colors go through `root.getUsageColor(percent)` (thresholds are configurable).
- Per-metric accents: CPU `#D97757`, RAM `#6A9BCC`, GPU `#9C87F5`.
- Panel number sizes use `font.pointSize`, not `font.pixelSize`: `pixelSize` is an int, so in-between sizes get truncated. Convert with pt = px × 0.75.
- Panel font family, size and weight come from the `panelFont*` config keys; `0` / empty means automatic. New text in the panel should respect them.
- Numeric settings use the `UnitSpinBox` inline component in `configGeneral.qml` (suffix, scale, decimals); it handles width, padding, typed input with either decimal separator, and display.
- Adding a setting means three edits: an `<entry>` in `main.xml`, a `cfg_<name>` property plus control in `configGeneral.qml`, and reading `Plasmoid.configuration.<name>` where it's used.

## License

GPL-3.0-or-later. `UsageRing.qml` and `TrendChart.qml` are adapted from the Claude Usage plasmoid; keep their attribution headers.
