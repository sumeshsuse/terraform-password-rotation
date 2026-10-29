module "password_rotation" {
  source = "../../modules/password-rotation"

  active_slot     = var.active_slot
  rotation_a      = var.rotation_a
  rotation_b      = var.rotation_b
  password_length = var.password_length
}