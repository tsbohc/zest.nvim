#!/bin/bash

# i have harnessed the power of badly written bash scripts to regenerate readme examles

for f in $HOME/.garden/etc/nvim.d/fnl/demo/fnl/*.fnl; do
  echo "compile $f"
  nvim "$f" +":w" +":q"
done

readme=$(<readme-template.md)

for lua_path in $HOME/.garden/etc/nvim.d/lua/demo/fnl/*.lua; do
  filename="$(basename "$lua_path")"
  key="${filename%.*}"
  fnl_path="$HOME/.garden/etc/nvim.d/fnl/demo/fnl/${filename//\.lua/\.fnl}"
  echo "add $key"

  fnl=$(<"$fnl_path")
  fnl="$(echo "$fnl" | tail -n +3 | head -n -2)"
  lua=$(<"$lua_path")
  lua="$(sed '$d' <<< "$lua")" # remove return statement
  readme="${readme//\{\{fnl:${key}\}\}/$fnl}"
  readme="${readme//\{\{lua:${key}\}\}/$lua}"
done

echo "$readme" > ../readme.md
