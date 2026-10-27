#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-2-Clause
"""A tiny stand-in for the Ourea API, for running the examples offline.

It serves the shared vector bodies in spec/vectors/bodies and answers each
prob= and totals= term it is asked, with made-up numbers. It is a test
fixture, not a model of the API: never point it at real data.

    python3 scripts/mock_server.py [port]    # prints the port it bound
"""
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

BODIES = Path(__file__).resolve().parent.parent / "spec" / "vectors" / "bodies"


def body(name):
    return json.loads((BODIES / name).read_text())


def window(text):
    text = text.rstrip("h")
    start, _, end = text.partition("-")
    return (0, int(start)) if not end else (int(start), int(end))


def answer_terms(forecast, query):
    if "prob" in query:
        answers = []
        for term in query["prob"][0].split(","):
            parts = term.split(":")
            variable, op, threshold = parts[0], parts[1], float(parts[2])
            start, end = window(parts[3])
            default = "total" if variable in ("precipitation", "snowfall") else "any"
            answers.append({
                "variable": variable, "op": op, "threshold": threshold,
                "window_start_hours": start, "window_end_hours": end,
                "aggregation": parts[4] if len(parts) > 4 else default,
                "from": "2026-11-15T00:00:00Z", "to": "2026-11-16T00:00:00Z",
                "probability": 0.42, "members": 131,
            })
        forecast["probabilities"] = answers
    if "totals" in query:
        totals = []
        for term in query["totals"][0].split(","):
            variable, _, spec = term.partition(":")
            start, end = window(spec)
            totals.append({
                "variable": variable, "window_start_hours": start, "window_end_hours": end,
                "from": "2026-11-15T00:00:00Z", "to": "2026-11-18T00:00:00Z",
                "quantiles": {"mean": 31.0, "p10": 12.0, "p25": 20.0, "p50": 29.0,
                              "p75": 40.0, "p90": 52.0, "min": 4.0, "max": 88.0},
                "members": 131,
            })
        forecast["window_totals"] = totals
    return forecast


def forecast_body(query):
    imperial = query.get("units", ["metric"])[0] == "imperial"
    forecast = body("forecast-imperial.json" if imperial else "forecast-metric.json")
    return answer_terms(forecast, query)


def current_body(units):
    forecast = body("forecast-metric.json")
    return {
        "location": forecast["location"], "alerts": [], "alerts_as_of": "2026-11-15T00:00:00Z",
        "sensor_count": 0, "sensors": [],
        "current": {"time": "2026-11-15T00:00:00Z", "temperature": -2.0, "condition": "snow",
                    "condition_text": "Snow", "condition_icon": "night_snow", "wind_speed": 6.0,
                    "wind_direction": 5.0, "source": "model"},
        "as_of": "2026-11-15T00:00:00Z", "model_run_initialized_at": "2026-11-15T00:00:00Z",
        "nowcast_hours": None, "units": units, "attribution": forecast["attribution"],
    }


def alerts_body():
    forecast = body("forecast-metric.json")
    return {"location": forecast["location"], "alert_count": 0, "as_of": "2026-11-15T00:00:00Z",
            "alerts": [], "attribution": forecast["attribution"]}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):  # noqa: N802 (http.server's naming)
        url = urlsplit(self.path)
        query = parse_qs(url.query)
        parts = [p for p in url.path.split("/") if p][2:]  # drop "api", "v1"
        status, payload = 200, None
        if parts[:1] == ["locations"] and len(parts) == 3:
            payload = forecast_body(query)
        elif parts[:1] == ["locations"] and len(parts) == 4 and parts[3] == "current":
            payload = current_body(query.get("units", ["metric"])[0])
        elif parts[:1] == ["locations"] and len(parts) == 4 and parts[3] == "alerts":
            payload = alerts_body()
        elif parts == ["forecast"]:
            lat, lon = float(query["lat"][0]), float(query["lon"][0])
            if not (24 <= lat <= 50 and -125 <= lon <= -66):
                status, payload = 400, body("error-outside-coverage.json")
            elif not self.headers.get("X-API-Key"):
                status, payload = 403, body("error-pro-required.json")
            else:
                payload = forecast_body(query)
        elif parts == ["search", "locations"]:
            payload = body("search.json")
        elif parts == ["catalog", "locations"]:
            payload = body("catalog-page-2.json" if "cursor" in query else "catalog-page-1.json")
        elif parts[:2] == ["catalog", "locations"]:
            payload = body("catalog-detail.json")
        elif parts == ["attribution"]:
            payload = body("attribution.json")
        else:
            status, payload = 404, body("error-not-found.json")
        data = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("ETag", '"mock-%d"' % hash(data))
        self.send_header("Cache-Control", "private, max-age=0")
        if self.headers.get("X-API-Key"):
            for name, value in (("Limit", "60"), ("Remaining", "59"), ("Reset", "60"), ("Policy", "60;w=60")):
                self.send_header("RateLimit-" + name, value)
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1]) if len(sys.argv) > 1 else 0), Handler)
    print(server.server_address[1], flush=True)
    server.serve_forever()
