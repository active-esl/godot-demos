#!/usr/bin/env python3
import json
import unittest
from datetime import date
from pathlib import Path

from scripts import gcal_export


class CalendarExportTest(unittest.TestCase):
    def test_fixture_normalizes_and_minimises_identifiers(self) -> None:
        cfg = json.loads(gcal_export.CONFIG.read_text())
        items = json.loads(gcal_export.FIXTURE.read_text())["items"]
        result = gcal_export.normalize(items, cfg, date(2026, 9, 2))
        self.assertEqual(result["timezone"], "Europe/London")
        self.assertEqual(len(result["bookings"]), 4)
        self.assertEqual(result["bookings"][0]["start"], 540)
        self.assertEqual(result["bookings"][0]["end"], 600)
        self.assertEqual(len(result["bookings"][0]["id"]), 16)
        self.assertNotIn("fixture-design-review", json.dumps(result))

    def test_cancelled_and_all_day_events_are_ignored(self) -> None:
        cfg = json.loads(gcal_export.CONFIG.read_text())
        items = [
            {"status": "cancelled", "start": {"dateTime": "2026-09-02T09:00:00+01:00"}, "end": {"dateTime": "2026-09-02T10:00:00+01:00"}},
            {"status": "confirmed", "start": {"date": "2026-09-02"}, "end": {"date": "2026-09-03"}},
        ]
        self.assertEqual(gcal_export.normalize(items, cfg, date(2026, 9, 2))["bookings"], [])


if __name__ == "__main__":
    unittest.main()
