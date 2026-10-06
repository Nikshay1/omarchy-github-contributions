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

The widget refreshes every 30 minutes and when the shell starts. It reads GitHub's public contribution calendar with `curl` and Python 3, without a personal access token or extra Python packages. Private contributions follow the visibility settings of the public GitHub profile. On a network failure, the last successful calendar remains visible with an error message.

## Development

```bash
omarchy plugin validate .
python3 fetch.py Nikshay1
```

## License

MIT
