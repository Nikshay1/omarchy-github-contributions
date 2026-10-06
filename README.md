# Omarchy GitHub Contributions

A native Omarchy 4 bar widget for your GitHub contribution calendar. The bar shows the latest seven days as green squares. Click it for the full year grid, contribution total, daily counts on hover, and the GitHub intensity legend.

## Install

```bash
omarchy plugin add https://github.com/Nikshay1/omarchy-github-contributions.git --enable --yes
```

The plugin defaults to `Nikshay1` and appears on the right side of the bar. To show a different public GitHub profile, set `username` on its entry in `~/.config/omarchy/shell.json`:

```json
{ "id": "io.github.nikshay1.contributions", "username": "your-github-name" }
```

The entry belongs in `bar.layout.right` (or another bar section). The Omarchy shell reloads the config when saved.

## Use

- **Left click:** Open or close the calendar.
- **Middle click:** Refresh immediately.
- **Drag the calendar heading:** Move the full calendar anywhere on the screen. Its position is saved.
- **Click ×:** Close the floating calendar.
- **Hover a square:** Show its date and contribution count.
- **Automatic refresh:** Every 30 minutes, and when the popup opens.

The plugin reads GitHub's public contribution calendar with `curl` and Python 3. It requires no token or extra Python packages. It shows the activity visible on a public GitHub profile, so private contributions follow that profile's visibility settings. If the network is unavailable, the last successful calendar stays visible and the popup shows an error.

## Development

```bash
omarchy plugin validate .
python3 fetch.py Nikshay1
```

The source is an Omarchy Quickshell plugin: `manifest.json`, `BarWidget.qml`, `Panel.qml`, and `fetch.py`.

## License

MIT
