# terraform-password-rotation

A small Terraform module that keeps two passwords, one **active** and one **backup**, so you can rotate a credential without cutting off anything that is using it.

The idea is simple: the live password never changes by surprise. You give the backup a fresh password, let your consumers learn it, then swap. The backup goes live, and the old live password becomes the new backup. With the guard script, nothing in this flow replaces the live password in place.

## How the task is covered

| Requirement | How it works | Proof |
|---|---|---|
| Two passwords on first creation | Two `random_password` resources, `slot_a` and `slot_b`. | test `create_both_passwords` |
| Rotate the backup only | Raise the counter of the backup slot (`rotation_a` or `rotation_b`). The counter is a `keepers` value, so only that slot gets a new password. | test `rotate_backup_only`, CI step "Guard blocks a change to the live password" |
| Swap active and backup | Change `active_slot`. Only the outputs switch, no password is regenerated. | test `swap_creates_no_new_passwords` |
| Idempotent | A password changes only when its counter changes. Applying the same inputs again does nothing. | test `same_inputs_change_nothing` |
| Substrate agnostic | The only provider is `hashicorp/random`. What uses the passwords is up to the caller. | `versions.tf` |
| At most two applies | Rotating takes one apply and swapping takes one. Doing both takes two. | CI job `guard-script` |
| Bonus: no rotate and swap together | The guard script does exactly one action per run and refuses any plan that would replace the live password. | CI job `guard-script` |

## What is in the repo

```
modules/password-rotation/   the module (two random_password slots)
  tests/rotation.tftest.hcl  terraform test scenarios
examples/basic/              an example driven by terraform.tfvars
scripts/rotate_or_swap.sh    the guard script
.github/workflows/ci.yml     fmt, validate, test and guard-script checks
```

## The module

| Input | Type | Default | Rule |
|---|---|---|---|
| `active_slot` | string | `"a"` | `a` or `b` |
| `rotation_a` | number | `1` | whole number, 0 or more |
| `rotation_b` | number | `1` | whole number, 0 or more |
| `password_length` | number | `24` | at least 16 |

| Output | Sensitive |
|---|---|
| `active` | yes |
| `backup` | yes |
| `active_slot` | no |
| `backup_slot` | no |

Each slot is a `random_password` with `keepers = { version = var.rotation_<slot> }`. Changing a counter regenerates that slot and nothing else. Changing `active_slot` regenerates nothing, it only decides which password is live.

## A rotation, step by step

```
start          active=a  backup=b
rotate         backup b gets a new password      (rotation_b + 1)
               consumers start accepting b
swap           active=b  backup=a                (no new passwords)
rotate         backup a gets a new password      (rotation_a + 1)
```

## The guard script

If you edit `terraform.tfvars` by hand, it is easy to change the live password by accident, for example by bumping the counter of the active slot, or by rotating and swapping in the same apply. The guard script allows exactly one safe action per run:

```bash
./scripts/rotate_or_swap.sh rotate   # new password in the backup slot
./scripts/rotate_or_swap.sh swap     # the backup becomes live
```

What it does:

1. Reads the current values from `examples/basic/terraform.tfvars` (or from the directory you pass as the second argument).
2. Works out the new values for the action you asked for.
3. Runs `terraform plan -out` with those values and reads the plan with `terraform show -json` and `jq`.
4. **Stops with exit code 1** if the plan would replace the password of the slot that is live after the apply.
5. Otherwise applies the exact plan it checked, writes the new values to `terraform.tfvars` and confirms the live slot.

The plan file is deleted when the script exits, because it contains the passwords in plain text.

Exit codes: `0` success, `1` blocked or error, `2` wrong usage.

You need Terraform 1.6 or newer, and `jq`.

## Try it

```bash
cd examples/basic
terraform init
terraform apply
cd ../..
./scripts/rotate_or_swap.sh rotate
./scripts/rotate_or_swap.sh swap
```

## Tests

```bash
terraform -chdir=modules/password-rotation init
terraform -chdir=modules/password-rotation test
```

CI runs `terraform fmt -check`, `validate`, `terraform test`, `shellcheck`, and an end-to-end run of the guard script: a rotate, a swap, and a change that it must block.

## Limits

- Terraform cannot compare "before" and "after" across applies. So the rule "no rotate and swap in one apply" is kept by the guard script, not by the module. Running `terraform apply` directly bypasses it.
- The guard script expects the example to be applied once first. On an empty state the plan would create both slots, which the script sees as a change to the live slot and blocks.
- Rotating and swapping together takes two applies, one for each.

## Security notes

- Terraform state and plan files hold the passwords in plain text, even though the outputs are marked sensitive. They are git-ignored here. In real use, keep state in a remote backend with encryption and restricted access.
- Read a password only when you need it: `terraform output -raw active`.