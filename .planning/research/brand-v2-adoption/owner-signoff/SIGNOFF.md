# Owner sign-off: brand v2 guidance

**Status:** pending

These paired drafts update the canonical agent and product guidance to match the owner-approved brand v2 direction. They have not been applied. `DESIGN.md` carries a temporary note while the canonical files remain on v1 values.

## Drafts and rationale

- [CLAUDE.md.patch](https://github.com/szTheory/mailglass/blob/main/.planning/research/brand-v2-adoption/owner-signoff/CLAUDE.md.patch) updates the brand history, v2 palette and fonts, lowercase prose rule, tagline, status-word rule, and v2 source of truth. It also preserves the seven code/API nouns while clarifying that operator screens use the plain-language terms from the v2 voice guide. Its final hunk corrects the Admin asset drift command to the existing `mix mailglass_admin.assets.build --check` check.
- [PRODUCT.md.patch](https://github.com/szTheory/mailglass/blob/main/.planning/research/brand-v2-adoption/owner-signoff/PRODUCT.md.patch) updates only brand commitments and capitalized prose uses of the product name. It preserves product scope, operating constraints, and the `impeccable:product-schema 1` marker.
- [SIGNOFF.md](https://github.com/szTheory/mailglass/blob/main/.planning/research/brand-v2-adoption/owner-signoff/SIGNOFF.md) is this paired runbook.

The v2 identity and voice come from `brandbook/v2/brand.json`; resolved color and type values come from `brandbook/tokens.json` and `brandbook/tokens.css`. The design contract is `DESIGN.md`. The older `brandbook/brand-book.md` is retired v1 material. Logo use by an adopter does not imply endorsement or certification.

## Review and apply as one change

Read the two patches and this sign-off artifact in the [repository folder](https://github.com/szTheory/mailglass/tree/main/.planning/research/brand-v2-adoption/owner-signoff). From `/Users/jon/projects/mailglass` on a branch, check and apply both patches together:

```sh
git apply --check .planning/research/brand-v2-adoption/owner-signoff/CLAUDE.md.patch .planning/research/brand-v2-adoption/owner-signoff/PRODUCT.md.patch && \
git apply .planning/research/brand-v2-adoption/owner-signoff/CLAUDE.md.patch .planning/research/brand-v2-adoption/owner-signoff/PRODUCT.md.patch && \
printf 'applied\n' > .planning/research/brand-v2-adoption/owner-signoff/STATUS
```

Commit the two canonical edits and the `STATUS` transition together. If either check fails, leave both canonical files untouched and refresh the paired drafts against the current files. Do not set `STATUS` to `applied` for a half-applied pair.
