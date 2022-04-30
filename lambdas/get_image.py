import requests
import json

def handler(event, context):
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
        },
        "body": json.dumps({
            "hdurl": requests.get("https://api.nasa.gov/planetary/apod?api_key=w5FXvJgVMYqcUDB4p4ddzcp05j9TGVQ9agL0udxO").json()["hdurl"]
        })
    }
