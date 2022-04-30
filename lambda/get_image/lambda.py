import json

import requests


def handler(event, context):
    apod_url = "https://api.nasa.gov/planetary/apod?api_key=w5FXvJgVMYqcUDB4p4ddzcp05j9TGVQ9agL0udxO"
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
        },
        "body": json.dumps({"hdurl": requests.get(apod_url).json()["hdurl"]}),
    }
