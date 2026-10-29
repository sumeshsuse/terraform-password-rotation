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

echo "active=$active rotation_a=$rotation_a rotation_b=$rotation_b"
