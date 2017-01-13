#!/usr/bin/env bash

cd "$(dirname $0)"

"${BINDGEN}" bindings.h -o ../src/freetype.rs \
  --no-unstable-rust \
  --blacklist-type "FT_(Int16|UInt16|Int32|UInt32|Int16|Int64|UInt64)" \
  --raw-line "pub type FT_Int16 = i16;" \
  --raw-line "pub type FT_UInt16 = u16;" \
  --raw-line "pub type FT_Int32 = i32;" \
  --raw-line "pub type FT_UInt32 = u32;" \
  --raw-line "pub type FT_Int64= i64;" \
  --raw-line "pub type FT_UInt64= u64;" \
  --generate=functions,types,vars       \
  --whitelist-function="FT_.*"         \
  --whitelist-type="FT_.*"             \
  --whitelist-var="FT_.*"             \
  -- -I/usr/include/freetype2
