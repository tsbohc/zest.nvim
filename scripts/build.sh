#!/bin/bash

# it's just a handful of files, so

declare -A files=(
  ["../fnl/zest/init.fnl"]="../lua/zest/init.lua"
  ["../fnl/zest/compile.fnl"]="../lua/zest/compile.lua"
  ["../plugin/init.fnl"]="../plugin/init.lua"
)

for source in "${!files[@]}"; do
  target="${files[${source}]}"
  fennel --compile "${source}" > "${target}"
  echo "<zest> ${source} => ${target}"
done
