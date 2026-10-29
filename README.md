# terraform-password-rotation

Zero-downtime password rotation with Terraform, using two password slots.

At any time one slot is **active** (live) and the other is the **backup**. You rotate the backup, switch traffic to it, and the old password stays valid as the new backup until the next rotation. No step ever changes the live password in place.

## Layout

```
modules/password-rotation/   reusable module (two random_password slots)
  tests/rotation.tftest.hcl  terraform test scenarios
examples/basic/              example driven by terraform.tfvars
scripts/rotate_or_swap.sh    guard script for safe rotations
.github/workflows/ci.yml     fmt, validate, test, guard-script checks
```

## Module

| Input | Type | Default | Rule |
|---|---|---|---|
| `active_slot` | string | `"a"` | `a` or `b` |
| `rotation_a` | number | `1` | whole number ≥ 0 |
| `rotation_b` | number | `1` | whole number ≥ 0 |
| `password_length` | number | `24` | ≥ 16 |

| Output | Sensitive |
|---|---|
| `active` | yes |
| `backup` | yes |
| `active_slot` | no |
| `backup_slot` | no |

Each slot is a `random_password` with `keepers = { version = var.rotation_<slot> }`. Changing a counter regenerates only that slot. Changing `active_slot` regenerates nothing, it only switches which password is live.

## Rotation flow

```
start          active=a  backup=b
rotate         backup b gets a new password      (rotation_b + 1)
               consumers start accepting b
swap           active=b  backup=a                (no new passwords)
rotate         backup a gets a new password      (rotation_a + 1)
```

## Guard script

Editing `terraform.tfvars` by hand makes it easy to change the live password by mistake, for example by bumping the active slot's counter or by rotating and swapping in one apply. The guard script allows exactly one safe action per run:

```bash
./scripts/rotate_or_swap.sh rotate   # new password in the backup slot
./scripts/rotate_or_swap.sh swap     # backup becomes live
```

What it does:

1. Reads the current values from `examples/basic/terraform.tfvars` (or the directory given as the second argument).
2. Computes the new values for the requested action.
3. Runs `terraform plan -out` with the new values and inspects the plan with `terraform show -json` and `jq`.
4. **Blocks with exit code 1** if the plan would replace the password of the slot that will be live after the apply.
5. Applies exactly the plan that was checked, then writes the new values to `terraform.tfvars` and verifies the live slot.

The plan file is deleted on exit because it contains the passwords in plain text.

Exit codes: `0` success, `1` blocked or error, `2` usage error.

Requirements: Terraform ≥ 1.6, `jq`.

## Usage

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

CI runs `terraform fmt -check`, `validate`, `terraform test`, `shellcheck`, and an end-to-end run of the guard script (rotate, swap, and a change it must block).

## Security notes

- Terraform state and plan files contain the passwords in plain text, even though the outputs are marked sensitive. They are git-ignored here. In real use, keep state in a remote backend with encryption and restricted access.
- Read a password only when needed: `terraform output -raw active`.
