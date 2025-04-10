resource "aws_config_config_rule" "kms_rotation_check" {
  name = "kms-key-rotation-enabled"
  source {
    owner             = "AWS"
    source_identifier = "KMS_KEY_ROTATION_ENABLED"
  }
}