# Final-system institutional boundary — UCKK Ops Console

**Scope:** `FC-11`, institutional operation and Moodle projection **only after independent authorization**. The console is not an alternate Ékole Core or a Moodle data source of truth.

## Added safe source inspection

`tools/inspect_ekole_pack.py` is an optional **Python 3.10+ offline read-only source inspector** for the existing `ekole.content-pack/0.1` format. Example:

```bash
python tools/inspect_ekole_pack.py "../ecole-pastorale"
python -m unittest discover -s tests -v
```

It rejects invalid or unsafe paths, duplicate JSON keys, malformed course references, inconsistent course IDs, missing source files and unsupported pack versions. It emits only content IDs and SHA-256 fingerprints, aggregate counts and deliberately **false** flags for `course_mapping_verified`, `moodle_write_permitted` and `moodle_applied`.

**This is neither a Moodle diff nor an apply operation**. It has no network, SSH, PowerShell, PHP CLI or SQL action. A source file is not a legitimate approval, course mapping, tenant identity or class enrollment. The existing UCKK PowerShell `source → validate → simulate → confirm → apply → verify` process and institution-specific permissions remain authoritative for real Moodle operations.

## Bilateral gates still required

Before any Ékole→Moodle integration is called implemented, the Ékole content owner and UCKK Moodle owner must adopt a versioned mapping for courses, categories and pathways, approve visibility/rights per source, authenticate an institutional operator, simulate the exact effect against the selected Moodle environment, confirm a bounded write and record a receiver-owned receipt and rollback/reconciliation path. The new inspector supports **source triage only**. No PowerShell runtime was available in the supplied analysis environment, so existing PowerShell modules were neither modified nor executed.
