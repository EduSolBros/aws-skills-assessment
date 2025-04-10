# AWS Skills Assessment

Each scenario is organized into its own folder with an individual readme explaining specific goals and usage.


## Structure
```
aws-skills-assessment/
├── README.md                      # Central summary and deployment guide
├── scenario1-key-rotation/       # KMS key rotation & monitoring
├── scenario2-apis/               # Public/private API design & routing
├── scenario3-protect-apigw/      # Blocking direct access to API GW
└── scenario4-backup-module/      # Backup automation using AWS Backup
```

Each scenario folder contains:

-   A detailed `readme` with explanations
    
-   Terraform files to deploy resources
    
-   Python scripts (if applicable)

## Deployment Steps (for all scenarios)

Follow these steps to deploy and test each part of the assessment:

#### 1. Initialize Terraform for any scenario:
```bash
cd scenario1-key-rotation     # or scenario2-apis, etc.
terraform init
```

#### 2. Plan the infrastructure:
```bash
terraform plan -var "account_id=<YOUR_ACCOUNT_ID>" -var "aws_region=us-east-1"
```

#### 3. Apply the changes
```bash
terraform apply -auto-approve
```

#### 4. Run Python scripts (if required)
```bash
cd scenario1-key-rotation
pip install boto3
python3 reencrypt.py --bucket my-bucket --dst-key arn:aws:kms:...:key/ID
```

> **Don’t forget to destroy resources after testing to avoid charges:**

```bash
terraform destroy -auto-approve
```

## Summary of Each Scenario

### Scenario 1 – Key Rotation & Encryption

Learn how to manage AWS KMS key rotation (automated and manual) and monitor compliance using AWS Config. Includes a script to re-encrypt S3 objects.

### Scenario 2 – API Architecture (Public vs Private)

Redesign existing public APIs into a hybrid model using API Gateway (private & public), CloudFront, and DNS routing. Includes path-based routing.

### Scenario 3 – API Gateway Protection

Block traffic that bypasses CloudFront and goes directly to API Gateway using VPC endpoint-based resource policies and optionally mutual TLS.

### Scenario 4 – Backup Strategy

Build a fully automated, secure backup plan using AWS Backup, Vault Lock, and tag-based resource selection. Includes cross-region/account retention and a reusable Terraform module.