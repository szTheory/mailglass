# Repository Social Preview Handoff

This checklist covers only the mailglass repository's GitHub social preview.
No image was uploaded during Phase 183, and no personal avatar or Gravatar change was made.

## Asset

- File: `brandbook/v2/social-card-1280x640.png`
- Format: PNG, 1280 × 640 pixels, 41,547 bytes, under GitHub's 1 MB limit
- SHA-256: recorded in `brandbook/brand.pin.json`
- The local preview should be the complete source artwork. Do not crop or stretch it.

## Owner upload and read-back

1. Open the repository settings: https://github.com/szTheory/mailglass/settings
2. Under **Social preview**, choose **Edit**, then **Upload an image...** and select
   `brandbook/v2/social-card-1280x640.png` from this checkout.
3. Reload the repository page: https://github.com/szTheory/mailglass
4. After the upload, run this read-only GraphQL query:

   ```sh
   gh api graphql -f query='{repository(owner:"szTheory",name:"mailglass"){usesCustomOpenGraphImage openGraphImageUrl}}'
   ```

   Confirm `usesCustomOpenGraphImage` is `true`. Fetch the returned `openGraphImageUrl` with a
   read-only HTTP GET and verify the returned image is a PNG with dimensions 1280 × 640 and a
   size below 1 MB. Record the returned URL and validation result in the phase verification.

The upload is an owner action and is not part of this plan. No GitHub settings or remote service
was changed by the plan.

## Personal avatars are out of scope

Do not upload the artwork to https://github.com/settings/profile or change a Gravatar. Those
settings identify the owner's personal accounts. Hex.pm has no per-package logo; HexDocs and the
README use repository assets automatically.

## Safari limitation

Real Safari tab appearance remains unobserved. The committed Playwright captures render the
favicon as an image. They do not observe real Safari tab chrome, OS scaling, or Safari's favicon
pipeline, and they are not represented as an acceptance result.
