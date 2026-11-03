## Review candidate: v2.10 UI repairs (phases 174–178)

Draft review only. This PR remains open and must not be merged from this checkpoint.

Candidate SHA: `8e501960bc975ed44b632ba5c74522e0c5d66f8c` (`fix(178-27): wait for scroll completion before End`).

### Scope

- Base `main`: `8328093e4a07d28251ec7f02dd0f37cda2fd6a7b`; 428 commits ahead, 698 files changed, 219504 insertions and 2169 deletions.
- Previous PR head: `a0a7450cc68afe84e25e69276c654d9e63422499`; this candidate is a fast-forward of 5 commits, with 4 files changed (556 insertions).

### Recovery changes and evidence

- Phase 178's Preview Capture Advisory now installs `inotify-tools` in its own job before starting the watcher.
- The inbound quick-view keyboard-access test now waits for native `scrollend` after PageDown before sending End. Hosted traces and an application-free Chromium reproduction showed End can be ignored when sent during the tail of the smooth-scroll animation. The accessibility, focus, boundary, and native-key assertions remain unchanged; no product code or dependency changed.
- Local verification: the inbound and delivery scroll-access cases passed three times each; the exact timing harness passed 12/12 after the fix and failed 3/12 with the fix reverted.
- The previous SHA's hosted Operator Browser Gate failed twice on the End-to-bottom assertion. This new SHA has not been run in hosted CI.

### Review links

- [Draft PR #317](https://github.com/szTheory/mailglass/pull/317)
- [Candidate comparison](https://github.com/szTheory/mailglass/compare/main...gsd/v2.10-ui-repairs-storybook)

This draft supports review only. It authorizes no merge, release, publication, deployment, or preview by itself.
