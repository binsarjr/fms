#!/bin/bash

set -e

# Get the current working directory
CURRENT_DIR=$(pwd)

echo "Preparing the environment..."
echo "Current working directory: $CURRENT_DIR"

# # check if dir /deps exists then exit
# if [ -d "/deps" ]; then
#   echo "Directory /deps already exists. Exiting."
#   exit 0
# fi

# Define the directory array
DIRS_TO_CHECK=(
  "./apps/frappe/node_modules"
  "./apps/frappe/frappe/public/node_modules"
  "./apps/erpnext/node_modules"
  "./apps/lms/node_modules"
  "./apps/lms/lms/public/node_modules"
  "./env/lib/python3.11/site-packages"
)

find_top_dirs() {
  local target_dir="$1"
  if [[ -z "$target_dir" ]]; then
    echo "Usage: find_top_dirs <dir_name>" >&2
    return 1
  fi

  find . -type d -name "$target_dir" ! -name "*.bak" | awk -v target="$target_dir" '
  {
    # Skip if directory ends with .bak (extra safety if path has .bak somewhere)
    if ($0 ~ "\\.bak$") next

    for (i in seen) {
      if (index($0, seen[i]) == 1 && $0 != seen[i]) next
      if (index(seen[i], $0) == 1 && seen[i] != $0) delete seen[i]
    }
    seen[++n] = $0
  }
  END {
    for (i = 1; i <= n; i++) print seen[i]
  }
  '
}

make_pths() {
  # Setup pth files (ini diperlukan agar setiap app yg ada di apps/ bisa di-import dalam virtual environment).
  while IFS= read -r line; do
    # Skip empty lines
    if [ -z "$line" ]; then
      continue
    fi

    name=$line

    # Create the filename with .pth extension
    filename="/home/frappe/frappe-bench/env/lib/python3.11/site-packages/${name}.pth"

    echo "Linking app apps/$name ..."

    # Create pth link to the app
    echo "/home/frappe/frappe-bench/apps/$name" >"$filename"
  done <sites/apps.txt
}

make_link() {
  local dir=$1
  safe_dir=$(echo "$dir" | sed 's|^\.\/|/deps/|')
  echo "$safe_dir"
  safe_dir_name=$(dirname "$safe_dir")
  mkdir -p "$safe_dir_name"
  if [ ! -d "$dir" ]; then
    return 0
  fi
  mv "$dir" "$safe_dir"
  echo "Creating symbolic link for $dir from $safe_dir"
  ln -s "$safe_dir" "$dir"
}

containerize_dir() {
  local dir=$1
  if [ -d "$dir" ]; then
    if [ -L "$dir" ]; then
      echo "Directory $dir already in container."
    else
      make_link "$dir"
    fi
  else
    make_link "$dir"
  fi
}

# Check each directory in the array
for dir in "${DIRS_TO_CHECK[@]}"; do
  containerize_dir "$dir"
done

make_pths

# find_top_dirs "node_modules" | while read -r dir; do
#   containerize_dir "$dir"
# done
