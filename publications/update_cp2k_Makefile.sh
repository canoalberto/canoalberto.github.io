#!/bin/bash

MAKEFILE="/opt/cp2k/exts/build_dbcsr/Makefile"

# Backup first
cp "$MAKEFILE" "$MAKEFILE.bak"

# Define the entries to ensure they exist
declare -A gpu_entries=(
  ["T4"]="  ARCH_NUMBER = 75"
  ["L40s"]="  ARCH_NUMBER = 89"
  ["A30"]="  ARCH_NUMBER = 80"
  ["H200"]="  ARCH_NUMBER = 90"
)

# Function to insert entry if missing
insert_gpuver() {
  local gpuver="$1"
  local arch_line="$2"
  local pattern="else ifeq \\\(\$\\(GPUVER\\),$gpuver\\\)"

  if ! grep -qE "$pattern" "$MAKEFILE"; then
    echo "Inserting entry for GPUVER=$gpuver"
    # Insert before the "else ifeq (,\$(ARCH_NUMBER))" line
    sed -i "/^else ifeq (,\$(ARCH_NUMBER))/i\\
else ifeq (\$(GPUVER),$gpuver)\n$arch_line" "$MAKEFILE"
  else
    echo "Entry for GPUVER=$gpuver already exists."
  fi
}

# Apply the function to all required entries
for gpuver in "${!gpu_entries[@]}"; do
  insert_gpuver "$gpuver" "${gpu_entries[$gpuver]}"
done

echo "Makefile modification complete."
