# Omarchy GitHub Contributions

A persistent GitHub contribution calendar for the Omarchy 4 desktop. It sits above the wallpaper and behind application windows, can be dragged by its heading when the desktop is exposed, and remembers its position. The grid shows a year of activity, the contribution total, and each day's count on hover.

## Install

```bash
omarchy plugin add https://github.com/Nikshay1/omarchy-github-contributions.git --enable --yes
```

This is a desktop widget. It does not add an item to the Omarchy bar. Enable or disable it with:

```bash
omarchy plugin enable io.github.nikshay1.contributions
omarchy plugin disable io.github.nikshay1.contributions
```

Drag the heading to place the calendar on your screen. The widget saves its location in `~/.local/state/omarchy/github-contributions.json` and restores it after a shell restart. That file also contains the `username` setting, which defaults to `Nikshay1`:

```json
{
  "username": "your-github-name",
  "x": 500,
  "y": 40
}
```

The widget refreshes every five minutes and when the shell starts. Right-click the heading to refresh immediately; the footer shows today's count and the last update time.

When the GitHub CLI (`gh`) is installed and signed in, the widget reads GitHub's GraphQL contribution calendar, preserving GitHub's dates and counts. Your credentials stay managed by `gh`. Run `gh auth login` if you need to sign in.

Without an authenticated GitHub CLI, it falls back to the public HTML calendar using `curl`. That calendar can lag behind your profile and stop at GitHub's server date. A notice identifies the public fallback and its last date. The plugin requires Python 3 and no extra Python packages. On a network failure, the last successful calendar remains visible with an error message.

## Development

```bash
omarchy plugin validate .
python3 fetch.py Nikshay1
python3 -B -m unittest test_fetch
```

## License

MIT
