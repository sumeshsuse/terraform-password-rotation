variables {
  rotation_a  = 1
  rotation_b  = 1
  active_slot = "a"
}

run "create_both_passwords" {
  command = apply

  assert {
    condition     = output.active_slot == "a" && output.backup_slot == "b"
    error_message = "Slot a should be active and slot b the backup after the first apply."
  }

  assert {
    condition     = output.active != output.backup
    error_message = "Active and backup must be different passwords."
  }

  assert {
    condition     = length(output.active) == 24 && length(output.backup) == 24
    error_message = "Both passwords should have the default length of 24."
  }
}

run "rotate_backup_only" {
  command = apply

  variables {
    rotation_b = 2
  }

  assert {
    condition     = output.active == run.create_both_passwords.active
    error_message = "The active password must not change when only the backup is rotated."
  }

  assert {
    condition     = output.backup != run.create_both_passwords.backup
    error_message = "The backup password should be new after its counter was increased."
  }
}

run "swap_creates_no_new_passwords" {
  command = apply

  variables {
    rotation_b  = 2
    active_slot = "b"
  }

  assert {
    condition     = output.active == run.rotate_backup_only.backup
    error_message = "After a swap, the old backup must be the new active password."
  }

  assert {
    condition     = output.backup == run.rotate_backup_only.active
    error_message = "After a swap, the old active must be the new backup password."
  }
}

run "same_inputs_change_nothing" {
  command = apply

  variables {
    rotation_b  = 2
    active_slot = "b"
  }

  assert {
    condition     = output.active == run.swap_creates_no_new_passwords.active && output.backup == run.swap_creates_no_new_passwords.backup
    error_message = "Applying the same inputs again must not change any password."
  }
}

run "rejects_unknown_active_slot" {
  command = plan

  variables {
    active_slot = "c"
  }

  expect_failures = [var.active_slot]
}

run "rejects_fractional_rotation" {
  command = plan

  variables {
    rotation_a = 1.5
  }

  expect_failures = [var.rotation_a]
}

run "rejects_short_password" {
  command = plan

  variables {
    password_length = 8
  }

  expect_failures = [var.password_length]
}