#!/usr/bin/env python3
"""Read GitHub's public contribution calendar without authentication."""

import json
import re
import subprocess
import sys
from datetime import date
from html.parser import HTMLParser


class CalendarParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.days = {}
        self.counts = {}
        self.tooltip_for = None
        self.heading = False
        self.heading_text = ""

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "td" and "ContributionCalendar-day" in a.get("class", ""):
            day = a.get("data-date", "")
            level = a.get("data-level", "")
            if re.fullmatch(r"\d{4}-\d{2}-\d{2}", day) and level in "01234":
                self.days[day] = {"date": day, "level": int(level), "count": 0}
                self.counts[a.get("id", "")] = day
        elif tag == "tool-tip":
            self.tooltip_for = self.counts.get(a.get("for", ""))
        elif tag == "h2" and a.get("id") == "js-contribution-activity-description":
            self.heading = True

    def handle_endtag(self, tag):
        if tag == "tool-tip":
            self.tooltip_for = None
        elif tag == "h2":
            self.heading = False

    def handle_data(self, data):
        if self.tooltip_for:
            match = re.search(r"(\d[\d,]*) contributions? on", data)
            if match:
                self.days[self.tooltip_for]["count"] = int(match.group(1).replace(",", ""))
        if self.heading:
            self.heading_text += data


def parse_calendar(html):
    parser = CalendarParser()
    parser.feed(html)
    days = [parser.days[key] for key in sorted(parser.days)]
    if len(days) < 350:
        raise ValueError("GitHub did not return a complete contribution calendar")
    total_match = re.search(r"(\d[\d,]*)\s+contributions?", parser.heading_text)
    if not total_match:
        raise ValueError("GitHub did not return the contribution total")
    return {"total": int(total_match.group(1).replace(",", "")), "days": days}


def main():
    username = sys.argv[1] if len(sys.argv) > 1 else ""
    if not re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?", username):
        raise ValueError("Set a valid GitHub username in the widget settings")
    response = subprocess.run(
        ["curl", "-fsSL", "--max-time", "15", "--retry", "2",
         "--user-agent", "omarchy-github-contributions/1.0",
         f"https://github.com/users/{username}/contributions"],
        check=True, capture_output=True, text=True,
    )
    result = parse_calendar(response.stdout)
    result["username"] = username
    result["fetched"] = date.today().isoformat()
    print(json.dumps(result, separators=(",", ":")))


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        message = "GitHub profile not found" if exc.returncode == 22 else "Could not reach GitHub"
        print(json.dumps({"error": message}))
        sys.exit(1)
    except (ValueError, subprocess.TimeoutExpired) as exc:
        print(json.dumps({"error": str(exc)}))
        sys.exit(1)
