variable "vault_name" { type = string }
variable "backup_role_arn" { type = string }
variable "cross_region_copy" {
  type = list(object({ destination_region = string, retention_days = number, kms_key_arn = string }))
}
variable "cross_account_copy" {
  type = list(object({ destination_account = string, retention_days = number, kms_key_arn = string }))
}
variable "selection_tags" { type = map(string) }