#!/usr/bin/env bash
set -euo pipefail

sed -E 's/^([[:space:]]*(Serial Number|UUID|Asset Tag|Service Tag|Inventory Tag):).*/\1 REDACTED/'
