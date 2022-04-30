import boto3


def handler(event, context):
    s3 = boto3.resource("s3")
    obj = s3.Object("apod2", "index")
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "text/html",
        },
        "body": obj.get()["Body"].read().decode("utf-8"),
    }
