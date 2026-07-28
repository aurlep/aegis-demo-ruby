#!/usr/bin/env python3
"""Convert a ZAP baseline JSON report into Aegis asset findings and post them.

Run in CI after the ZAP scan. Reads the ZAP JSON report, maps each alert to a
finding on the app (identified by the repository), and posts them to the Aegis
asset-findings ingest as a 'generic' envelope. Stdlib only.
"""
import glob
import json
import os
import urllib.request

RISK = {"3": "high", "2": "medium", "1": "low", "0": "info"}


def _load_report():
    for name in ("zap-report.json", "report_json.json"):
        if os.path.exists(name):
            return json.load(open(name, encoding="utf-8"))
    for path in glob.glob("**/*.json", recursive=True):
        try:
            doc = json.load(open(path, encoding="utf-8"))
        except Exception:
            continue
        if isinstance(doc, dict) and "site" in doc:
            return doc
    return None


def main() -> int:
    url = os.environ.get("AEGIS_URL")
    token = os.environ.get("AEGIS_INGEST_TOKEN")
    asset = os.environ.get("ASSET", "dast-target")
    org = os.environ.get("AEGIS_ORG", "7b5b6e10-f2c2-4e6e-83fb-41c999b01d47")
    if not (url and token):
        print("Aegis secrets not set; skipping DAST ingest.")
        return 0

    report = _load_report()
    if not report:
        print("No ZAP JSON report found; skipping.")
        return 0

    findings = []
    for site in report.get("site", []):
        target = site.get("@name", "")
        for alert in site.get("alerts", []):
            findings.append(
                {
                    "rule_id": str(alert.get("pluginid") or alert.get("cweid") or alert.get("name")),
                    "title": alert.get("name", ""),
                    "severity": RISK.get(str(alert.get("riskcode", "0")), "info"),
                    "component": target,
                    "raw": {
                        "cweid": alert.get("cweid"),
                        "confidence": alert.get("confidence"),
                        "desc": (alert.get("desc") or "")[:400],
                        "solution": (alert.get("solution") or "")[:300],
                    },
                }
            )

    if not findings:
        print("ZAP reported no alerts.")
        return 0

    body = json.dumps(
        {
            "source": "zap",
            "asset": {"kind": "service", "identifier": asset, "hostname": asset},
            "findings": findings,
        }
    ).encode()
    endpoint = url.rstrip("/") + "/api/v1/assets/findings:ingest?format=generic&scanner=zap"
    req = urllib.request.Request(endpoint, data=body, method="POST")
    req.add_header("Authorization", "Aegis-CI " + token)
    req.add_header("X-Aegis-Organization", org)
    req.add_header("Content-Type", "application/json")
    try:
        resp = urllib.request.urlopen(req, timeout=30)  # noqa: S310
        print(f"Posted {len(findings)} DAST findings:", resp.read().decode()[:200])
    except Exception as exc:  # noqa: BLE001
        print("Aegis ingest skipped:", exc)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
