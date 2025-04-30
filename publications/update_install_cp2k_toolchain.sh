#!/bin/bash

FILE="./install_cp2k_toolchain.sh"
BACKUP="${FILE}.bak"

# Backup the original file
cp "$FILE" "$BACKUP" || { echo "Failed to create backup"; exit 1; }

# Define new GPU cases and their ARCH_NUM values
declare -A new_cases=(
  [T4]='export ARCH_NUM="75"'
  [L40s]='export ARCH_NUM="89"'
  [A30]='export ARCH_NUM="80"'
  [H200]='export ARCH_NUM="90"'
)

# Find start of 'case ${GPUVER}' block
start_line=$(grep -nE '^\s*case\s+\$\{?GPUVER\}?\s*in' "$FILE" | cut -d: -f1)
if [[ -z "$start_line" ]]; then
  echo "No 'case \${GPUVER}' block found in $FILE"
  exit 1
fi

# Find end of the case block (the matching 'esac')
end_line=$(tail -n +"$start_line" "$FILE" | grep -nE '^\s*esac' | head -n1 | cut -d: -f1)
end_line=$((start_line + end_line - 1))

# Extract case block to temp file
tmp_block=$(mktemp)
sed -n "${start_line},${end_line}p" "$FILE" > "$tmp_block"

# Insert missing cases before the default '*)' line
for gpu in "${!new_cases[@]}"; do
  if ! grep -q "^\s*${gpu})" "$tmp_block"; then
    sed -i "/^\s*\*)/i \ \ ${gpu})\n\ \ \ \ ${new_cases[$gpu]}\n\ \ \ \ ;;" "$tmp_block"
    echo "Inserted case for $gpu"
  else
    echo "Case for $gpu already exists"
  fi
done

# Replace the original case block
sed -i "${start_line},${end_line}d" "$FILE"
sed -i "${start_line}r $tmp_block" "$FILE"
rm "$tmp_block"

# Update GPU list in the pattern match line (e.g. K20X | K40 | ... | no))
sed -i -E \
  's/^( *K20X[^\|]*\|[^)]*)no\)/\1T4 | L40s | A30 | H200 | no)/' \
  "$FILE"

echo "Updated GPU list in pattern match line."
