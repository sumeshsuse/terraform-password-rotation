#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 <rotate|swap> [example-dir]" >&2
  exit 2
}

[[ $# -ge 1 ]] || usage
action="$1"
dir="${2:-examples/basic}"
tfvars="$dir/terraform.tfvars"

[[ -f "$tfvars" ]] || { echo "error: $tfvars not found" >&2; exit 1; }

read_var() {
  sed -nE "s/^$1[[:space:]]*=[[:space:]]*\"?([^\"]*)\"?[[:space:]]*$/\1/p" "$tfvars"
}

active=$(read_var active_slot)
rotation_a=$(read_var rotation_a)
rotation_b=$(read_var rotation_b)

[[ "$active" =~ ^[ab]$ ]] || { echo "error: active_slot must be a or b, got '$active'" >&2; exit 1; }

if [[ "$active" == "a" ]]; then backup="b"; else backup="a"; fi

new_active="$active"
new_a="$rotation_a"
new_b="$rotation_b"

case "$action" in
  rotate)
    if [[ "$backup" == "a" ]]; then new_a=$((rotation_a + 1)); else new_b=$((rotation_b + 1)); fi
    ;;
  swap)
    new_active="$backup"
    ;;
  *)
    usage
    ;;
esac

echo "active_slot: $active -> $new_active"
echo "rotation_a:  $rotation_a -> $new_a"
echo "rotation_b:  $rotation_b -> $new_b"
