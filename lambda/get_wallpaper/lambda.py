def handler(event, context):
    try:
        import boto3

        s3 = boto3.resource("s3")
        obj = s3.Object("apod2", "index")
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "text/html",
            },
            "body": obj.get()["Body"].read().decode("utf-8"),
        }
    except Exception as exception:
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "text/html",
            },
            "body": exception,
        }
