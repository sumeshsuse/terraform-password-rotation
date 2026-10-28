output "active" {
  description = "Password that is live."
  value       = module.password_rotation.active
  sensitive   = true
}

output "backup" {
  description = "Password ready to take over."
  value       = module.password_rotation.backup
  sensitive   = true
}

output "active_slot" {
  description = "Slot that is live."
  value       = module.password_rotation.active_slot
}

output "backup_slot" {
  description = "Slot that is the backup."
  value       = module.password_rotation.backup_slot
}