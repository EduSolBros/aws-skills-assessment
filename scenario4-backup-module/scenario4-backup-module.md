
## Scenario #4: Enterprise Backup Policy with AWS Backup

### Module Design

This Terraform module automates:

1.  **Backup Vault** with Vault Lock (WORM).
    
2.  **Backup Plan** with cross-region and cross-account copy.
    
3.  **Tag-based resource selection** (`ToBackup=true`, `Owner=<email>`).
    
4.  **KMS encryption** for backups.


### variables.tf
```tf
variable "vault_name" { type = string }
variable "backup_role_arn" { type = string }
variable "cross_region_copy" {
  type = list(object({ destination_region = string, retention_days = number, kms_key_arn = string }))
}
variable "cross_account_copy" {
  type = list(object({ destination_account = string, retention_days = number, kms_key_arn = string }))
}
variable "selection_tags" { type = map(string) }
```

### main.tf
```tf
resource "aws_backup_vault" "this" {
  name               = var.vault_name
  encryption_key_arn = var.cross_region_copy[0].kms_key_arn
}
resource "aws_backup_vault_lock_configuration" "lock" {
  backup_vault_name  = aws_backup_vault.this.name
  changeable_for_days = 7
  max_retention_days  = 3650
}
resource "aws_backup_plan" "plan" {
  name = "${var.vault_name}-plan"
  rule {
    rule_name         = "daily"
    schedule          = "cron(0 5 * * ? *)"
    target_vault_name = aws_backup_vault.this.name
    lifecycle { delete_after = 30 }
    dynamic "copy_action" {
      for_each = var.cross_region_copy
      content {
        destination_vault_arn = aws_backup_vault.this.arn
        destination_region    = copy_action.value.destination_region
        lifecycle { delete_after = copy_action.value.retention_days }
      }
    }
    dynamic "copy_action" {
      for_each = var.cross_account_copy
      content {
        destination_vault_arn = aws_backup_vault.this.arn
        lifecycle { delete_after = copy_action.value.retention_days }
      }
    }
  }
}
resource "aws_backup_selection" "selection" {
  name         = "${var.vault_name}-selection"
  iam_role_arn = var.backup_role_arn
  plan_id      = aws_backup_plan.plan.id
  dynamic "tag_selector" {
    for_each = var.selection_tags
    content {
      type  = "STRINGEQUALS"
      key   = tag_selector.key
      value = tag_selector.value
    }
  }
}
```
### example_usage.tf
```tf
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
```