# Phase 90 Gate Evidence — brandbook-fable/ (GATE-01 + GATE-02)

- **Date:** 2026-06-11
- **HEAD:** `106229bd`
- **Gate script:** `.planning/phases/90-quality-gate-and-uat/gate.sh` (run from repo root)
- **Frozen codex baseline:** `09a84dd4`

## Documented denylist exclusion (the only one)

Check 4's process-vocabulary denylist filters exactly one false-positive
pattern: `align-items:[[:space:]]*baseline`. `brandbook-fable/index.html` uses
the functional CSS value `align-items: baseline` twice; `baseline` there is a
CSS keyword, not process vocabulary, and rewriting working layout CSS to dodge
a denylist word would be wrong (same rationale as decision [79-01]
text-base-content). NO other exclusion is applied — any other hit is a real
leak that must be fixed in the source file.

## Scripted Gate Runs (GATE-01)

### Run 1 — 2026-06-11, HEAD 106229bd — verbatim output

```
CHECK-1 PASS
CHECK-2 PASS
CHECK-3 PASS
CHECK-4 PASS
CHECK-5 PASS
CHECK-6 PASS
CHECK-7 PASS (folder 256 KB, index.html 79789 B)
CHECK-8 PASS (2 shape elements, 16x16 viewBox)
CHECK-9 PASS
GATE-PASS
```

Exit code: 0. All 9 checks passed on the first full run; no fixes to
`brandbook-fable/` were required.

| Check | What it proves | Result |
|---|---|---|
| 1 | All 12 SVGs xmllint-parse; inventory exactly 8 assets + 6 examples (4 SVG + 2 HTML) | PASS |
| 2 | tokens.json parses as JSON | PASS |
| 3 | Every href/src resolves locally per-file; zero external URLs / url(http) / @import / fetch / script-src | PASS |
| 4 | Zero process-vocabulary hits (Phase 88/89 base regex + word-bounded extension; single documented CSS exclusion) | PASS |
| 5 | Zero `<text` and zero `font-family` in assets/ AND examples/ SVGs | PASS |
| 6 | Zero `<rect>` in every mark; the two square social avatars carry exactly one 240x240 plate each (documented exception) | PASS |
| 7 | Folder 256 KB <= 500 KB; index.html 79,789 B <= 153,600 B; no file > 100 KB | PASS |
| 8 | Favicon: 2 shape elements (<= 3), viewBox="0 0 16 16" | PASS |
| 9 | Tree clean outside .planning/; frozen brandbook/ identical to 09a84dd4; nothing outside brandbook-fable/ + .planning/ changed in 09a84dd4..HEAD | PASS |
