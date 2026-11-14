# Brand v2 compatibility policy

Brand v2 changes the words and visuals on screens and in docs. This policy
lists the public names that must not move while that happens, and a test reads
the table below to prove each one still exists in the code.

On-screen and docs words are glossed, never renamed: every public name in the table below stays.

<!-- compat-table:start -->
| name | kind | package | proof |
|------|------|---------|-------|
| `Mailglass.Operator.Timeline` | module | mailglass | `Code.ensure_loaded?` |
<!-- compat-table:end -->

## Gloss, don't rename

A gloss is a plainer word on a screen or in docs prose. The public name it
describes keeps working and keeps its spelling.

<!-- gloss-table:start -->
| public name | on-screen word | gloss |
|-------------|----------------|-------|
| `Operator` | `Admin` | screen text and docs prose only; the public name stays |
<!-- gloss-table:end -->
