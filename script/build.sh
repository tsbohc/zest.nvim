#!/usr/bin/env bash

# it's just a handful of files, so

zest="$HOME/code/zest.nvim/master"

declare -A files=(
  ["$zest/fnl/zest/init.fnl"]="$zest/lua/zest/init.lua"
  ["$zest/fnl/zest/compile.fnl"]="$zest/lua/zest/compile.lua"
  ["$zest/plugin/init.fnl"]="$zest/plugin/init.lua"
)

for source in "${!files[@]}"; do
  target="${files[${source}]}"
  fennel --compile "${source}" > "${target}"
  echo "<zest> ${source} => ${target}"
done
