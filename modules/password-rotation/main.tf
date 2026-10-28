resource "random_password" "slot_a" {
  length = var.password_length

  keepers = {
    version = var.rotation_a
  }
}

resource "random_password" "slot_b" {
  length = var.password_length

  keepers = {
    version = var.rotation_b
  }
}

locals {
  passwords = {
    a = random_password.slot_a.result
    b = random_password.slot_b.result
  }

  backup_slot = var.active_slot == "a" ? "b" : "a"
}