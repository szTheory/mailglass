---
artifact: tooling-defects
stable_ids: true
created: 2026-07-28
---

# TOOLING-DEFECTS — Recognized GSD Tooling Defects

> This register is deliberately **milestone-independent** — it lives at the `.planning/` root, not
> under a `milestones/<version>-phases/` directory. Both existing registers in this repo
> (`.planning/RATCHET-GAP-REGISTER.md`, `.planning/research/v1.14/DEFECT-REGISTER.md`) are milestone-
> scoped by design and get archived away with their milestone. A defect record whose only job is to be
> recognized by a future run of the same command must survive a milestone boundary, so this file
> deliberately breaks that pattern.

## How to read this register

- Stable `TOOL-NN` IDs, never renumbered once assigned.
- Each entry carries **Symptom**, **Occurrences**, **Evidence**, **Mitigations**, and **Status**.
- The Symptom line is the load-bearing content: someone re-running the command must recognize the
  failure from what they see on screen, not from a git-archaeology exercise.

---

## TOOL-01 — `gsd-tools query phases.clear` deletes phase directories without writing the archive

**Symptom:** `cleared: N` is reported and the command exits looking successful, but no
`milestones/<version>-phases/` directory is written. The phase directories are gone; there is no
archive to show for it.

**Occurrences (two, both in this repo):**

1. **v2.0 phases 132-137.** `b5fed519` ("docs: start milestone v2.1") deleted 48 files under
   `.planning/phases/132-*` … `137-*`. `a629fb82` restored all 48 under
   `.planning/milestones/v2.0-phases/`. Per-file `git hash-object` comparison against `b5fed519^`:
   `ok=48 missing=0 differ=0`.
2. **v2.1 phases 138-140**, during v2.2's own opening on 2026-07-28. `70099869` moved 39 files;
   `git show --name-status -M 70099869` reports all 39 as `R100`. The delete and the by-hand repair
   landed in the same commit.

**Evidence** — the only place this defect was recorded before this file existed, quoted verbatim from
`70099869`'s commit body:

> `gsd-tools query phases.clear --archive-version v2.1` reported `cleared: 3` but deleted the three
> phase directories without writing the archive.

**Mitigations, ranked:**

- **PRIMARY (post-condition check).** After any `phases.clear`, list `.planning/milestones/<outgoing>-
  phases/` and compare its file count against `git show --stat HEAD` **before committing**. A count
  mismatch, or a missing directory, is the defect showing up in front of you — catch it there, not
  three commits later.
- **necessary but insufficient — does NOT prevent this.** Passing `--archive-version <outgoing>`
  explicitly. It was passed on the 2026-07-28 occurrence (`gsd-tools query phases.clear
  --archive-version v2.1`) and the archive was still not written. Record it anyway: `new-milestone`
  runs `state.milestone-switch` **before** `phases.clear`, so a live `STATE.md` read at that point would
  file the archive under the *incoming* milestone rather than the outgoing one — the flag is still
  required for correct filing, it is simply not a fix for this defect. It is recorded here as
  necessary but insufficient, not as the fix.

**Status / tool version observed:** `gsd-sdk v1.42.3` (`~/.claude/gsd-core/bin/lib/milestone.cjs`),
which archives rather than hard-deletes (`#1871`), refuses to run against uncommitted phase work
(`#1447`), and accepts `--archive-version` (`#2288`).

**Live recurrence risk:** v2.2's own milestone close invokes the same command against phases 141-144.
Run the post-condition check above before that close is committed.
