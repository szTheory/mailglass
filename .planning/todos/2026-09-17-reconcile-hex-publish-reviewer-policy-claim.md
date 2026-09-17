---
created: 2026-09-17T16:55:00.000Z
title: CLAUDE.md claims hex-publish has no required reviewers; it has one
area: docs
files:
  - CLAUDE.md (Commit & Branch Conventions)
  - GitHub environment `hex-publish` protection rules
priority: backlog
---

## Problem

CLAUDE.md states releases are "fully hands-free" and that "the
`hex-publish` environment intentionally has no required reviewers",
adding that tightening this back to a required-reviewer gate would be "a
deliberate policy change, not the current default."

The live environment has a `required_reviewers` protection rule
(szTheory). The 2.6.0 publish fan-out stopped for three manual
approvals — one per package.

So the doc describes the opposite of the deployed configuration.

## Fix

Decide which one is intended, then make the other match:

- If the reviewer gate is wanted (it is a reasonable control on a
  public-registry publish, and it fired usefully during 2.6.0), rewrite
  the CLAUDE.md paragraph to describe the approval step as part of the
  ceremony.
- If hands-free is wanted, remove the protection rule deliberately and
  record why.

Do not "fix" this by removing the protection rule to make the doc true.
The doc is the cheap thing to change; the control is not.

## Why it matters

An agent or maintainer reading CLAUDE.md plans a release that needs no
human present, then the fan-out blocks on an approval nobody is waiting
for. That is how a publish gets stranded half-done, with some packages
live and others not.
