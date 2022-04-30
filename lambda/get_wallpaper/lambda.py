import json

import boto3
import requests


def handler(event, context):
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "text/html"},
        "body": boto3.resource("s3")
        .Object("apod2", "index")
        .get()["Body"]
        .read()
        .decode("utf-8")
        .replace("image_url", requests.get("https://api.nasa.gov/planetary/apod?api_key=w5FXvJgVMYqcUDB4p4ddzcp05j9TGVQ9agL0udxO").json()["hdurl"]),
    }
