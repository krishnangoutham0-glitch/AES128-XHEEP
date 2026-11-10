#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

: "${ORFS_ROOT:?Set ORFS_ROOT to the OpenROAD-flow-scripts checkout}"
if [[ ! -f "$ORFS_ROOT/flow/Makefile" ]]; then
  printf 'OpenROAD-flow-scripts Makefile not found under ORFS_ROOT=%s\n' "$ORFS_ROOT" >&2
  exit 1
fi

make_command="${MAKE:-}"
if [[ -z "$make_command" ]]; then
  if command -v gmake >/dev/null 2>&1; then
    make_command="$(command -v gmake)"
  else
    make_command="$(command -v make)"
  fi
fi
if ! make_version="$("$make_command" --version 2>/dev/null)" ||
  [[ "$make_version" != *"GNU Make"* ]]; then
  printf 'GNU Make is required; install it or set MAKE to its executable.\n' >&2
  exit 1
fi

"$make_command" -C "$ORFS_ROOT/flow" \
  DESIGN_CONFIG="$project_root/physical_design/nangate45/xheep/openroad/config.mk" \
  WORK_HOME="${WORK_HOME:-$project_root/build/openroad}" \
  NUM_CORES="${NUM_CORES:-2}" \
  all
