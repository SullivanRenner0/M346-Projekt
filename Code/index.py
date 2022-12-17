import boto3
import os
from PIL import Image
import pathlib
from io import BytesIO

s3 = boto3.resource('s3')

def resize_image(obj, des_bucket):
    size = 300, 300
    in_mem_file = BytesIO()
    client = boto3.client('s3')

    file_byte_string = obj.get()['Body'].read()
    im = Image.open(BytesIO(file_byte_string))

    im.thumbnail(size, Image.ANTIALIAS)
    # ISSUE : https://stackoverflow.com/questions/4228530/pil-thumbnail-is-rotating-my-image
    im.save(in_mem_file, format=im.format)
    in_mem_file.seek(0)

    response = client.put_object(
        Body=in_mem_file,
        Bucket=des_bucket,
        Key='resizedPrefix_replace' + obj.key
    )

def lambda_handler(event, context):
    bucket = s3.Bucket('sourcebucket_replace')
    # print("WantedKey: " + str(event['Records'][0]['s3']['object']['key']))
    for obj in bucket.objects.all():
        # print("ObjKey: " + str(obj.key))
        if (obj.key == event['Records'][0]['s3']['object']['key']):
            resize_image(obj, 'destbucket_replace')