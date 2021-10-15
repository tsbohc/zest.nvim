#!/bin/bash

# it's just a handful of files, so

zest="$HOME/code/zest.nvim/runtime"

declare -A files=(
  ["$zest/fnl/zest/init.fnl"]="$zest/lua/zest/init.lua"
)

for source in "${!files[@]}"; do
  target="${files[${source}]}"
  fennel --compile "${source}" > "${target}"
  echo "<zest> ${source} => ${target}"
done
