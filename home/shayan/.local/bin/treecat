#!/usr/bin/env bash
# treecat - pretty tree view with file contents, with optional clipboard mode

show_hidden=false
copy_mode=false

# Parse flags
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -a|--all) show_hidden=true ;;
    -c|--copy) copy_mode=true ;;
    *) echo "Usage: treecat [-a|--all] [-c|--copy]" >&2; exit 1 ;;
  esac
  shift
done

# Choose tree command
if $show_hidden; then
  tree_cmd=(tree -a)
else
  tree_cmd=(tree)
fi

# Create a temp file (only if copy mode)
tmpfile=""
if $copy_mode; then
  tmpfile=$(mktemp /tmp/treecat.XXXXXX)
fi

# Main logic
"${tree_cmd[@]}" | while IFS= read -r line; do
  echo "$line"
  name=$(echo "$line" | sed -n 's/.*[├└]── //p')
  [ -z "$name" ] && continue
  fullpath=$(find . -type f -name "$name" | head -n1)
  # Skip binary files
  if [[ -f "$fullpath" ]] && ! file --brief --mime "$fullpath" | grep -q "binary"; then
    sed "s/^/$(echo "$line" | sed 's/[^│ ]/ /g')    /" "$fullpath"
  fi
done | if $copy_mode; then
  # Save to file
  tee "$tmpfile" >/dev/null

  sleep 0.5

  copied=false

  # Priority: use user's alias "clip" first
  if command -v clip &>/dev/null; then
    clip < "$tmpfile" && copied=true
  elif command -v wl-copy &>/dev/null; then
    wl-copy < "$tmpfile" && copied=true
  elif command -v copyq &>/dev/null; then
    copyq copy - < "$tmpfile" && copied=true
  elif command -v xclip &>/dev/null; then
    xclip -selection clipboard < "$tmpfile" && copied=true
  elif command -v pbcopy &>/dev/null; then
    pbcopy < "$tmpfile" && copied=true
  fi

  sleep 0.7
  rm -f "$tmpfile"

  if $copied; then
    echo "✅ Copied tree output to clipboard."
  else
    echo "❌ Could not find a clipboard utility (clip, wl-copy, copyq, xclip, pbcopy)." >&2
  fi
else
  cat
fi
