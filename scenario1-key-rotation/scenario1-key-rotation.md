# Scenario #1: Encryption Management & Key Rotation

## Overview

Our regulator now mandates key rotation for every AWS KMS key. In a mature environment, rotating keys without disrupting services is non-trivial. Below are two seasoned approaches, followed by monitoring strategies.

## Option A: Automated KMS Rotation + On-the-fly Re-encryption

#### 1. Enable built-in rotation (annual) on each KMS key:

```tf
resource "aws_kms_key" "app_key" {
  description         = "Application data key with automatic rotation"
  enable_key_rotation = true
}
```

#### 2. Alias management remains unchanged—aliases point to the key ID automatically.

#### 3. Re-encrypt existing data via a lightweight Python script:

```py
# reencrypt.py
import boto3, argparse
def reencrypt_s3(bucket, prefix, dst_key):
    s3 = boto3.client('s3')
    for obj in s3.list_objects_v2(Bucket=bucket, Prefix=prefix).get('Contents', []):
        s3.copy_object(
            Bucket=bucket, Key=obj['Key'],
            CopySource={'Bucket': bucket, 'Key': obj['Key']},
            ServerSideEncryption='aws:kms', SSEKMSKeyId=dst_key
        )
if __name__ == '__main__':
    p = argparse.ArgumentParser(); p.add_argument('--bucket', required=True)
    p.add_argument('--dst-key', required=True); args = p.parse_args()
    reencrypt_s3(args.bucket, '', args.dst_key)
```

#### 4. Apply the script to S3, RDS snapshots, and DynamoDB tables in batches.

> Why I like this approach: It leverages AWS-managed rotation and lets you re-encrypt data at your own pace.

## Option B: Blue-Green Key Rotation with Staged Cutover

#### 1. Create a new key (alias/app-key-v2) alongside the existing one.
#### 2. Deploy updated applications referencing the new alias.
#### 3. Gradually re-encrypt data using AWS CLI or Lambda-backed orchestrator.
#### 4. Deprecate the old key once no resources reference it.

> Why this feels safe: You get zero downtime and a clear rollback path by switching aliases.

## Monitoring Non‑Compliant Resources
Use AWS-managed services to detect any resource still encrypted under a non‑rotated key:

- **AWS Config**
    ```tf
    resource "aws_config_config_rule" "kms_rotation_check" {
        name = "kms-key-rotation-enabled"
        source {
            owner             = "AWS"
            source_identifier = "KMS_KEY_ROTATION_ENABLED"
        }
    }
    ```
- **AWS Config Aggregator** to consolidate across accounts/regions.
- **Custom AWS Config rule** (Lambda) to flag S3 buckets, RDS instances, and DynamoDB tables whose KmsKeyId points to a key older than 1 year.