module "enterprise_backup" {
  source             = "../scenario4-backup-module"
  vault_name         = "corp-backup"
  backup_role_arn    = "arn:aws:iam::123456789012:role/AWSBackupServiceRole"
  cross_region_copy = [
    { destination_region = "eu-west-1", retention_days = 90, kms_key_arn = "arn:aws:kms:...:key/abc" }
  ]
  cross_account_copy = [
    { destination_account = "210987654321", retention_days = 365, kms_key_arn = "arn:aws:kms:...:key/xyz" }
  ]
  selection_tags = { ToBackup = "true", Owner = "ops@company.com" }
}