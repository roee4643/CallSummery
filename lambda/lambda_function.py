import json
import boto3
import urllib.parse
import time

transcribe = boto3.client('transcribe')

def lambda_handler(event, context):
    print("=== Lambda Triggered ===")
    print("Event Received:", json.dumps(event))  # כאן נוודא שהאירוע מגיע

    try:
        record = event['Records'][0]
        bucket = record['s3']['bucket']['name']
        key = urllib.parse.unquote_plus(record['s3']['object']['key'])

        job_name = f"transcription-{int(time.time())}"
        file_uri = f"s3://{bucket}/{key}"
        media_format = key.split('.')[-1]

        response = transcribe.start_transcription_job(
            TranscriptionJobName=job_name,
            Media={'MediaFileUri': file_uri},
            MediaFormat=media_format,
            LanguageCode='en-US'
        )
        print("Transcription started:", json.dumps(response))
    except Exception as e:
        print("Error occurred:", str(e))
        raise e

    return {
        'statusCode': 200,
        'body': 'Transcription job started'
    }
