import boto3
import argparse

def reencrypt_s3(bucket, prefix, dst_key):
    s3 = boto3.client('s3')
    paginator = s3.get_paginator('list_objects_v2')
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        for obj in page.get('Contents', []):
            s3.copy_object(
                Bucket=bucket,
                Key=obj['Key'],
                CopySource={'Bucket': bucket, 'Key': obj['Key']},
                ServerSideEncryption='aws:kms',
                SSEKMSKeyId=dst_key
            )

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--bucket', required=True, help='Name of the S3 bucket')
    parser.add_argument('--prefix', default='', help='Prefix to filter objects in the bucket')
    parser.add_argument('--dst-key', required=True, help='ARN of the KMS key to use for re-encryption')
    args = parser.parse_args()

    reencrypt_s3(args.bucket, args.prefix, args.dst_key)
