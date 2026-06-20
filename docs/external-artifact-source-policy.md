# External Artifact Source Policy

## Purpose

BoostLab preserves Ultimate behavior, but it must not permanently depend on an
Ultimate-author personal mirror or another non-official artifact mirror when a
tool downloads executable or installer content.

This policy records source governance only. It does not approve downloads,
installers, binaries, artifact execution, or runtime URL substitution.

## Source Classes

`OfficialVendorDirect` means the source URL is controlled by the original
vendor, software project, or official distribution channel. These URLs may
remain direct when a tool is otherwise approved.

`UltimateAuthorHostedArtifact` means the Ultimate source downloads a file from
the Ultimate author or author-controlled mirror, such as `Ultimate-Files`.
BoostLab should not rely on that external personal link as final production
infrastructure.

`ThirdPartyMirrorArtifact` means a file is downloaded from a non-official mirror
not controlled by the original vendor/project or BoostLab.

`BoostLabControlledMirror` is a future BoostLab-owned mirror of the exact same
artifact.

## Mirror Rules

Official vendor downloads remain direct.

Author-hosted or third-party mirror artifacts are tracked as
`NeedsBoostLabMirror` unless a BoostLab-controlled mirror exists and the exact
original file SHA-256 is recorded.

Mirror substitution is allowed only when:

* the mirrored file is byte-for-byte the same as the original artifact,
* SHA-256 is recorded and verified before use,
* the tool-specific behavior remains source-equivalent, and
* Yazan approves the production mirror/use in the relevant implementation phase.

No mirror policy may weaken Ultimate parity, remove source-defined behavior, or
silently replace an Ultimate workflow with a different package, installer,
switch set, or source.

## Manifest

`config/ExternalArtifactSources.psd1` records the current audit scope:

* reached tools from BIOS Information through Visual C++,
* original source URL,
* source classification,
* future BoostLab mirror status, and
* known SHA-256 when available.

This manifest is separate from `config/ArtifactProvenance.psd1`.
`ArtifactProvenance.psd1` remains the execution/provenance approval list and is
not changed by this policy.

## Current Phase Boundaries

This audit does not scan or classify unreached tools after Visual C++.
It does not implement Graphics Configuration Center, Windows-stage tools, or
Advanced-stage tools.

It does not download, upload, vendor, or commit binary files.
