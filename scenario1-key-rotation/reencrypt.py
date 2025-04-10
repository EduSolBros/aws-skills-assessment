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