variable "active_slot" {
  description = "Slot that is live: a or b."
  type        = string
}

variable "rotation_a" {
  description = "Rotation counter of slot a."
  type        = number
}

variable "rotation_b" {
  description = "Rotation counter of slot b."
  type        = number
}

variable "password_length" {
  description = "Length of each generated password."
  type        = number
}