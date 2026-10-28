variable "active_slot" {
  description = "Slot that is currently active. The other slot is the backup."
  type        = string
  default     = "a"
  nullable    = false

  validation {
    condition     = contains(["a", "b"], var.active_slot)
    error_message = "active_slot must be \"a\" or \"b\"."
  }
}

variable "rotation_a" {
  description = "Rotation counter for slot a. Increase it to generate a new password in slot a."
  type        = number
  default     = 1
  nullable    = false

  validation {
    condition     = var.rotation_a >= 0 && floor(var.rotation_a) == var.rotation_a
    error_message = "rotation_a must be a whole number, 0 or higher."
  }
}

variable "rotation_b" {
  description = "Rotation counter for slot b. Increase it to generate a new password in slot b."
  type        = number
  default     = 1
  nullable    = false

  validation {
    condition     = var.rotation_b >= 0 && floor(var.rotation_b) == var.rotation_b
    error_message = "rotation_b must be a whole number, 0 or higher."
  }
}

variable "password_length" {
  description = "Length of each generated password."
  type        = number
  default     = 24
  nullable    = false

  validation {
    condition     = var.password_length >= 16
    error_message = "password_length must be at least 16."
  }
}
