#!/usr/bin/env python3
"""Export a privacy-minimised Google Calendar day for the Godot room panel."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
from datetime import date, datetime, time, timedelta, timezone
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "scripts" / "gcal_config.json"
OUTPUT = ROOT / "demos" / "room-booking" / "data" / "calendar_day.json"
FIXTURE = ROOT / "scripts" / "fixtures" / "google_events.json"
SECRET_ENV = "AESL_ROOM_DISPLAY_GCAL_SA_JSON"
SECRET_PATH_ENV = "AESL_ROOM_DISPLAY_GCAL_SA_JSON_PATH"
SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]


def _clean(value: Any, limit: int) -> str:
    return re.sub(r"[\x00-\x1f\x7f]+", " ", str(value or "")).strip()[:limit]


def _host(description: str) -> str:
    match = re.search(r"^Host:\s*(.+)$", description or "", re.MULTILINE)
    return _clean(match.group(1), 31) if match else "Organizer"


def _parse(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def _minute_of_day(value: datetime, tz: ZoneInfo) -> int:
    local = value.astimezone(tz)
    return local.hour * 60 + local.minute


def normalize(items: list[dict[str, Any]], cfg: dict[str, Any], day: date, source: str = "google") -> dict[str, Any]:
    tz = ZoneInfo(cfg.get("timezone", "Europe/London"))
    bookings: list[dict[str, Any]] = []
    for event in items:
        if event.get("status") == "cancelled":
            continue
        start_raw = (event.get("start") or {}).get("dateTime")
        end_raw = (event.get("end") or {}).get("dateTime")
        if not start_raw or not end_raw:  # Room panels ignore all-day notices.
            continue
        start = _parse(start_raw)
        end = _parse(end_raw)
        if start.astimezone(tz).date() != day and end.astimezone(tz).date() != day:
            continue
        description = str(event.get("description") or "")
        opaque_id = hashlib.sha256(str(event.get("id") or "event").encode()).hexdigest()[:16]
        bookings.append(
            {
                "id": opaque_id,
                "start": _minute_of_day(start, tz),
                "end": _minute_of_day(end, tz),
                "title": _clean(event.get("summary") if cfg.get("publish_titles") else "Busy", 39) or "Meeting",
                "host": _host(description) if cfg.get("publish_hosts") else "Organizer",
                "checked_in": "Checked-in: yes" in description,
            }
        )
    bookings.sort(key=lambda booking: (booking["start"], booking["end"]))
    now = datetime.now(tz)
    offset = int((now.utcoffset() or timedelta()).total_seconds() // 60)
    return {
        "source": source,
        "calendar_summary": cfg.get("calendar_summary", "Active-ESL Room A (Demo)"),
        "room": cfg.get("room", "Meeting room"),
        "floor": cfg.get("floor", ""),
        "timezone": str(tz),
        "utc_offset_minutes": offset,
        "day": day.isoformat(),
        "synced_at": datetime.now(timezone.utc).isoformat(),
        "bookings": bookings,
    }


def _google_items(cfg: dict[str, Any], day: date) -> list[dict[str, Any]]:
    raw = os.environ.get(SECRET_ENV, "")
    secret_path = os.environ.get(SECRET_PATH_ENV, "")
    if not raw and secret_path:
        raw = Path(secret_path).read_text()
    if not raw:
        raise RuntimeError(f"set {SECRET_ENV} or {SECRET_PATH_ENV}")
    from google.oauth2 import service_account
    from googleapiclient.discovery import build

    tz = ZoneInfo(cfg.get("timezone", "Europe/London"))
    start = datetime.combine(day, time.min, tzinfo=tz)
    end = start + timedelta(days=1)
    credentials = service_account.Credentials.from_service_account_info(
        json.loads(raw), scopes=SCOPES
    )
    service = build("calendar", "v3", credentials=credentials, cache_discovery=False)
    items: list[dict[str, Any]] = []
    page_token = None
    while True:
        response = (
            service.events()
            .list(
                calendarId=cfg["calendar_id"],
                timeMin=start.isoformat(),
                timeMax=end.isoformat(),
                singleEvents=True,
                orderBy="startTime",
                pageToken=page_token,
            )
            .execute()
        )
        items.extend(response.get("items") or [])
        page_token = response.get("nextPageToken")
        if not page_token:
            return items


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    parser.add_argument("--fixture", type=Path)
    parser.add_argument("--day", type=date.fromisoformat)
    args = parser.parse_args()
    cfg = json.loads(CONFIG.read_text())
    tz = ZoneInfo(cfg.get("timezone", "Europe/London"))
    selected_day = args.day or datetime.now(tz).date()
    if args.fixture:
        items = (json.loads(args.fixture.read_text()).get("items") or [])
        source = "fixture"
    else:
        items = _google_items(cfg, selected_day)
        source = "google"
    output = normalize(items, cfg, selected_day, source)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_suffix(args.output.suffix + ".tmp")
    temporary.write_text(json.dumps(output, indent=2, ensure_ascii=False) + "\n")
    os.replace(temporary, args.output)
    print(f"exported {len(output['bookings'])} room events for {selected_day} -> {args.output}")


if __name__ == "__main__":
    main()
