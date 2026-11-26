#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Waslla
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="${REPO_ROOT}/package"
METADATA_FILE="${PACKAGE_DIR}/metadata.json"

if [[ ! -f "${METADATA_FILE}" ]]; then
    echo "Error: ${METADATA_FILE} not found." >&2
    exit 1
fi

VERSION=$(grep -oP '"Version":\s*"\K[^"]+' "${METADATA_FILE}" || echo "0.9.2")
ID=$(grep -oP '"Id":\s*"\K[^"]+' "${METADATA_FILE}" || echo "io.github.wasib2005.uselesslauncher")
OUTPUT_FILE="${REPO_ROOT}/${ID}-${VERSION}.plasmoid"

echo "Packaging ${ID} version ${VERSION}..."
rm -f "${OUTPUT_FILE}"

(
    cd "${PACKAGE_DIR}"
    zip -r "${OUTPUT_FILE}" . -x "*.DS_Store" "*~" "*.swp"
)

echo "Created: ${OUTPUT_FILE}"
echo "Ready for upload to store.kde.org (OpenDesktop) under 'Plasma 6 Applets'."
