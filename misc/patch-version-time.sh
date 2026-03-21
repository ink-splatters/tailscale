#!/usr/bin/env bash
set -euo pipefail

version_file="${1:-VERSION}"
timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if [[ ! -f "${version_file}" ]]; then
    echo "error: VERSION file not found: ${version_file}" >&2
    exit 1
fi

first_line="$(sed -n '1p' "${version_file}")"

{
    printf "%s\n" "${first_line}"
    printf "time %s\n" "${timestamp}"
} >"${version_file}"

echo "patched ${version_file}: time ${timestamp}"
