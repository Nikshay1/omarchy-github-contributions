import json
import subprocess
import unittest
from datetime import date, timedelta
from unittest.mock import patch

from fetch import fetch_calendar, parse_graphql


def api_response():
    start, end = date(2025, 10, 7), date(2026, 10, 7)
    days = []
    for offset in range((end - start).days + 1):
        day = (start + timedelta(days=offset)).isoformat()
        count = 277 if offset == 0 else 5 if day == "2026-10-07" else 0
        days.append({"date": day, "contributionCount": count,
                     "contributionLevel": "FOURTH_QUARTILE" if count else "NONE"})
    return json.dumps({"data": {"user": {"contributionsCollection": {
        "contributionCalendar": {"totalContributions": 282,
                                 "weeks": [{"contributionDays": days}]}
    }}}})


class CalendarTests(unittest.TestCase):
    def test_api_preserves_today_and_zero_yesterday(self):
        result = parse_graphql(api_response())
        self.assertEqual(result["total"], 282)
        self.assertEqual(result["days"][-2], {"date": "2026-10-06", "count": 0, "level": 0})
        self.assertEqual(result["days"][-1], {"date": "2026-10-07", "count": 5, "level": 4})

    @patch("fetch.subprocess.run")
    def test_authenticated_api_takes_priority_over_public_html(self, run):
        run.return_value = subprocess.CompletedProcess([], 0, stdout=api_response())
        result = fetch_calendar("Nikshay1")
        self.assertEqual(result["total"], 282)
        self.assertEqual(result["source"], "github-api")
        run.assert_called_once()
        self.assertEqual(run.call_args.args[0][:3], ["gh", "api", "graphql"])

    def test_inconsistent_total_is_rejected(self):
        response = json.loads(api_response())
        response["data"]["user"]["contributionsCollection"]["contributionCalendar"]["totalContributions"] = 278
        with self.assertRaises(ValueError):
            parse_graphql(json.dumps(response))


if __name__ == "__main__":
    unittest.main()
