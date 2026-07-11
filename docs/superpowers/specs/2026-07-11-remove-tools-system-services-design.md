# Remove System Services from the Tools Feature

## Goal

Remove Tailscale, OpenSSH server, and C/C++ build-tools installation from the
`tools` Dev Container Feature. The feature should retain only its terminal and
CLI tool installers.

## Scope

- Remove the `installTailscale`, `installSshd`, and `installBuildTools` options.
- Remove Tailscale and SSH runtime metadata: the entrypoint, Linux capabilities,
  persistent mounts, and container environment variables.
- Remove the corresponding installer functions, option variables, and calls.
- Delete the Tailscale entrypoint and tests dedicated to the three removed
  capabilities.
- Remove obsolete option values and assertions from the remaining tools tests.
- Update the feature description and bump its version from `1.5.3` to `1.6.0`.
- Regenerate the feature README rather than editing generated content manually.

Other features in this repository are unchanged.

## Compatibility

This is an intentional breaking schema change. Existing configurations that set
the three removed options must delete those settings. A minor version bump is
used because Dev Container Feature versions follow the repository's existing
release convention and the feature must receive a new GHCR tag to avoid stale
cached content.

## Verification

- Validate that the manifest is valid JSON and no removed option or runtime
  metadata remains.
- Run the tools feature's focused test suite.
- Confirm generated documentation reflects the reduced option set.
- Search `src/tools` and `test/tools` for stale Tailscale, SSHD, and build-tools
  references.
