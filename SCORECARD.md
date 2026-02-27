# Scorecard

> Score a repo before remediation. Fill this out first, then use SHIP_GATE.md to fix.

**Repo:** avatar-face-mvp
**Date:** 2026-02-27
**Type tags:** [desktop]

## Pre-Remediation Assessment

| Category | Score | Notes |
|----------|-------|-------|
| A. Security | 3/10 | No SECURITY.md, no threat model, template only |
| B. Error Handling | 7/10 | GDScript error handling present, no structured shape |
| C. Operator Docs | 7/10 | Excellent README + HANDBOOK, no CHANGELOG |
| D. Shipping Hygiene | 5/10 | CI solid, no version in manifest, no verify script |
| E. Identity (soft) | 10/10 | Logo, translations, landing page, metadata present |
| **Overall** | **32/50** | |

## Key Gaps

1. No SECURITY.md — no vulnerability reporting process
2. No CHANGELOG.md
3. Version in tts-bridge at 0.1.0 — needs 1.0.0 promotion
4. No Security & Data Scope in README

## Remediation Priority

| Priority | Item | Estimated effort |
|----------|------|-----------------|
| 1 | Create SECURITY.md + threat model in README | 5 min |
| 2 | Create CHANGELOG.md, bump version to 1.0.0 | 5 min |
| 3 | Add SHIP_GATE.md + SCORECARD.md | 5 min |

## Post-Remediation

| Category | Before | After |
|----------|--------|-------|
| A. Security | 3/10 | 10/10 |
| B. Error Handling | 7/10 | 10/10 |
| C. Operator Docs | 7/10 | 10/10 |
| D. Shipping Hygiene | 5/10 | 10/10 |
| E. Identity (soft) | 10/10 | 10/10 |
| **Overall** | **32/50** | **50/50** |
