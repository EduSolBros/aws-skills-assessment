resource "aws_kms_key" "app_key" {
  description         = "Application data key with automatic rotation"
  enable_key_rotation = true
}