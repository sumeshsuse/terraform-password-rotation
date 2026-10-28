output "active" {
  description = "Password of the active slot."
  value       = local.passwords[var.active_slot]
  sensitive   = true
}

output "backup" {
  description = "Password of the backup slot."
  value       = local.passwords[local.backup_slot]
  sensitive   = true
}

output "active_slot" {
  description = "Slot that is currently active."
  value       = var.active_slot
}

output "backup_slot" {
  description = "Slot that is currently the backup."
  value       = local.backup_slot
}