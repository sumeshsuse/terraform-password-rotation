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

for tool in terraform jq; do
  command -v "$tool" >/dev/null || { echo "error: $tool is not installed" >&2; exit 1; }
done

plan="guard.tfplan"
trap 'rm -f "$dir/$plan"' EXIT

terraform -chdir="$dir" plan -input=false -out="$plan" \
  -var "active_slot=$new_active" \
  -var "rotation_a=$new_a" \
  -var "rotation_b=$new_b" >/dev/null

changed=$(terraform -chdir="$dir" show -json "$plan" \
  | jq -r '.resource_changes[]? | select(.change.actions != ["no-op"]) | .address')

echo "resources that change: ${changed:-none}"

if grep -q "random_password.slot_${new_active}$" <<<"$changed"; then
  echo "BLOCKED: this plan would replace the live password in slot $new_active" >&2
  exit 1
fi

echo "OK: the live password is untouched"

terraform -chdir="$dir" apply -input=false "$plan"

sed -i.bak -E \
  -e "s/^(active_slot[[:space:]]*=[[:space:]]*).*/\1\"$new_active\"/" \
  -e "s/^(rotation_a[[:space:]]*=[[:space:]]*).*/\1$new_a/" \
  -e "s/^(rotation_b[[:space:]]*=[[:space:]]*).*/\1$new_b/" \
  "$tfvars"
rm -f "$tfvars.bak"

live=$(terraform -chdir="$dir" output -raw active_slot)
[[ "$live" == "$new_active" ]] || { echo "error: expected active slot $new_active after apply, got $live" >&2; exit 1; }

echo "DONE: $action applied, live slot is $live, $tfvars updated"
