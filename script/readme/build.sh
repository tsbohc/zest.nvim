#!/bin/bash

# i have harnessed the power of badly written bash scripts to regenerate readme examles

readme_path="../../readme.md"
template=$(<template.md)

for source in fnl/*.fnl; do
  target=${source/fnl\//lua\/}
  target=${target%.*}.lua
  source_filename="$(basename "$source")"
  target_filename="$(basename "$target")"

  echo "$source -> $target"
  fennel --compile "$source" > "$target"

  template="${template//\{\{${source_filename}\}\}/$fnl}"
  template="${template//\{\{${target_filename}\}\}/$lua}"
done

if [ -f "$readme_path" ]; then
  echo "$template" > "$readme_path"
fi

#for lua_path in $HOME/.garden/etc/nvim/lua/demo/fnl/*.lua; do
#  filename="$(basename "$lua_path")"
#  key="${filename%.*}"
#  fnl_path="$HOME/.garden/etc/nvim/fnl/demo/fnl/${filename//\.lua/\.fnl}"
#  echo "add $key"
#
#  fnl=$(<"$fnl_path")
#  fnl="$(echo "$fnl" | tail -n +3 | head -n -2)"
#  lua=$(<"$lua_path")
#  lua="$(sed '$d' <<< "$lua")" # remove return statement
#  readme="${readme//\{\{fnl:${key}\}\}/$fnl}"
#  readme="${readme//\{\{lua:${key}\}\}/$lua}"
#done
#
#echo "$readme" > ../../readme.md
