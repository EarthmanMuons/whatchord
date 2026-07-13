#!/usr/bin/env bash
# Bundle a tagged source archive plus the WhatKey preprint for a manual
# Zenodo deposit, so the paper is visible on the record without untarring.
#
# Usage: tool/whatkey/zenodo_bundle.sh [tag]   (defaults to the latest tag)
#
# Everything is taken from the tag, not the working tree, so the bundle
# matches the released state exactly; git archive output is deterministic
# for a given tag. Upload the bundle as a "New version" of the existing
# Zenodo record to keep all deposits under one concept DOI.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

tag="${1:-$(git describe --tags --abbrev=0)}"
git rev-parse --verify --quiet "refs/tags/${tag}" >/dev/null || {
	echo "error: tag '${tag}' not found" >&2
	exit 1
}

out="build/zenodo/${tag}"
mkdir -p "${out}"

archive="${out}/whatchord-${tag}.tar.gz"
git archive --format=tar.gz --prefix="whatchord-${tag}/" -o "${archive}" "${tag}"

# The paper carries its own version (draft-version in main.typ), which is
# allowed to trail the repository tag when a research release did not touch
# the paper; the PDF is named by the version it claims for itself.
paper_version="$(
	{ git show "${tag}:research/whatkey/paper/main.typ" 2>/dev/null || true; } |
		sed -n 's/^#let draft-version = "\(.*\)"$/\1/p' | head -1
)"
if [[ -z ${paper_version} ]]; then
	echo "error: could not read draft-version from main.typ at ${tag}" >&2
	echo "(does the paper exist at this tag?)" >&2
	exit 1
fi

paper="${out}/whatkey-preprint-${paper_version}.pdf"
if ! git show "${tag}:research/whatkey/paper/main.pdf" >"${paper}" 2>/dev/null; then
	rm -f "${paper}"
	echo "error: research/whatkey/paper/main.pdf does not exist at ${tag}" >&2
	exit 1
fi

echo "Zenodo bundle for ${tag} (paper ${paper_version}):"
ls -lh "${out}"
echo
echo "Upload both files as a New Version of the existing Zenodo record,"
echo "with the record version set to ${tag}; the preprint filename keeps"
echo "the paper's own version, which may trail the repository tag."
