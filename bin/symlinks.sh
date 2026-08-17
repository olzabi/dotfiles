#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../symlinks.conf"
. "$SCRIPT_DIR/utils.sh"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Configuration file not found: $CONFIG_FILE"
  exit 1
fi

create_symlinks() {
  info "Creating symbolic links..."
  local created=0 skipped=0 warned=0
  while IFS=: read -r source target || [ -n "$source" ]; do
    if [[ -z "$source" || -z "$target" || "$source" == \#* ]]; then
      continue
    fi

    source=$(eval echo "$source")
    target=$(eval echo "$target")

    if [ ! -e "$source" ]; then
      error "Source not found: '$source' — skipping '$target'."
      ((warned++))
      continue
    fi

    if [ -L "$target" ]; then
      existing=$(readlink "$target")
      existing_abs=$(realpath -m "$(dirname "$target")/$existing")
      source_abs=$(realpath -m "$source")
      if [ "$existing" = "$source" ] || [ "$existing_abs" = "$source_abs" ]; then
        # Already correct — no need to spam a line per entry, just tally it.
        ((skipped++))
      else
        warn "Symlink exists but points elsewhere: $target → $existing (expected $source)"
        ((warned++))
      fi
      continue

    fi
    if [ -e "$target" ]; then
      warn "File or directory already exists (not a symlink): $target"
      ((warned++))
      continue
    fi

    target_dir=$(dirname "$target")
    if [ ! -d "$target_dir" ]; then
      mkdir -p "$target_dir"
      info "Created directory: $target_dir"
    fi

    ln -s "$source" "$target"
    success "Created symlink: $target → $source"
    ((created++))
  done < <(expand_conf "$CONFIG_FILE")
  info "Done: $created created, $skipped already up to date, $warned need attention."
}

delete_symlinks() {
  info "Deleting symbolic links..."

  while IFS=: read -r source target || [ -n "$target" ]; do
    if [[ -z "$source" || -z "$target" || "$source" == \#* ]]; then
      continue
    fi

    target=$(eval echo "$target")

    if [ -L "$target" ]; then
      rm "$target"
      success "Deleted symlink: $target"
    elif [ "$include_files" == true ] && [ -f "$target" ]; then
      rm -rf "$target"
      success "Deleted file: $target"
    else
      warn "Not found (or not a symlink): $target"
    fi
  done <"$CONFIG_FILE"
}

# shellcheck disable=SC2317
if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
  case "$1" in
  "--create")
    create_symlinks
    ;;
  "--delete")
    if [ "$2" == "--include-files" ]; then
      include_files=true
    fi
    delete_symlinks
    ;;
  "--help")
    echo "Usage: $0 [--create | --delete [--include-files] | --help]"
    ;;
  *)
    error "Unknown argument: '$1'"
    error "Usage: $0 [--create | --delete [--include-files] | --help]"
    exit 1
    ;;
  esac
fi
