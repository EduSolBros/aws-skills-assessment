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