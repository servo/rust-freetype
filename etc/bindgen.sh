#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

SUBMODULE_UPDATE_CMD="git submodule update --init --recursive"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || \
  die "bindgen.sh must be run from a git checkout"

FT_SUBMODULE="${REPO_ROOT}/freetype-sys"
FT_INCLUDE="${FT_SUBMODULE}/freetype2/include"

[ -f "${FT_INCLUDE}/ft2build.h" ] || \
  die "freetype-sys is not fully checked out; run '${SUBMODULE_UPDATE_CMD}'"

nested_submodule_status=$(git -C "${FT_SUBMODULE}" submodule status --recursive 2>/dev/null) || \
  die "failed to inspect submodules under freetype-sys"

if printf '%s\n' "${nested_submodule_status}" | grep -Eq '^[+-U]'; then
  die "freetype-sys submodules are not checked out at the recorded commits; run '${SUBMODULE_UPDATE_CMD}'"
fi

if [ -n "$(git -C "${FT_SUBMODULE}" status --porcelain --ignore-submodules=none)" ]; then
  die "freetype-sys or one of its submodules has local changes; clean it before regenerating bindings"
fi

BINDGEN="${BINDGEN:-bindgen}"

# We replace the FT_ integer types of known widths, since we can do better.
#
# We blacklist FT_Error and import our own in order to have convenience methods
# on it instead of being a plain integer.
"${BINDGEN}" bindings.h -o ../src/freetype.rs \
  --blocklist-type "FT_(Int16|UInt16|Int32|UInt32|Int16|Int64|UInt64)" \
  --raw-line "pub type FT_Int16 = i16;" \
  --raw-line "pub type FT_UInt16 = u16;" \
  --raw-line "pub type FT_Int32 = i32;" \
  --raw-line "pub type FT_UInt32 = u32;" \
  --raw-line "pub type FT_Int64= i64;" \
  --raw-line "pub type FT_UInt64= u64;" \
  --blocklist-type "FT_Error" \
  --raw-line "pub use FT_Error;" \
  --generate=functions,types,vars       \
  --allowlist-function="FT_.*"         \
  --allowlist-type="FT_.*"             \
  --allowlist-var="FT_.*"             \
  -- -I"${FT_INCLUDE}"
