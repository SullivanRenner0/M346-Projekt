#!/bin/bash

#nötiges installieren 
echo " "
echo "Packages werden vorbereitet ..."
sudo apt-get -qq update > /dev/null
sudo apt-get install -qq zip > /dev/null
sudo apt-get install -qq jq > /dev/null

echo "Packages wurden fertig vorbereitet"

#Variabeln deklarieren
bucket1original="sr-lg-m346-projekt-original"
bucket2original="sr-lg-m346-projekt-compressed"
functionNameoriginal="copyImage"
layerName="pillow-layer"
zipName="lambda.zip"
compressesPrefix="resized_"
py="index.py"
pil="pillow.zip"
pcFuncName="CopyImage"
pyTempName="CopyImage"
pyTemp="$pyTempName.py"
region="us-east-1"

#Einzigartige Namen für die Buckets finden
bucket1=$bucket1original
bucket2=$bucket2original
functionName=$functionNameoriginal
i=0

while `aws s3api head-bucket --bucket $bucket1 2>/dev/null || aws s3api head-bucket --bucket $bucket2 2>/dev/null || aws lambda get-function --function-name $functionName 2>/dev/null`
do
i=$((i+1))
bucket1="$bucket1original-$i"
bucket2="$bucket2original-$i"
functionName="$functionNameoriginal-$i"
done

#Buckets erstellen
echo ""
aws s3 mb s3://$bucket1 > /dev/null
echo "Bucket \"$bucket1\" wurde erstellt"
aws s3 mb s3://$bucket2 > /dev/null
echo "Bucket \"$bucket2\" wurde erstellt"

#Layer erstellen
layer=$(aws lambda publish-layer-version \
    --layer-name $layerName \
    --zip-file fileb://$pil \
    --compatible-runtimes python3.9 \
    --region "$region" \
    | jq -r '.LayerVersionArn')
echo "Layer \"$layerName\" wurde erstellt"

#Funktion löschen
aws lambda delete-function --function-name $functionName &> /dev/null

#Funktion erstellen
cp $py $pyTemp > /dev/null
sed -i -e 's/sourcebucket_replace/'$bucket1'/g' $pyTemp
sed -i -e 's/destbucket_replace/'$bucket2'/g' $pyTemp
sed -i -e 's/resizedPrefix_replace/'$compressesPrefix'/g' $pyTemp
sed -i -e 's/lambda_handler_replace/'$pcFuncName'/g' $pyTemp
zip -r9 $zipName $pyTemp > /dev/null
rm $pyTemp

accountNumber=`aws sts get-caller-identity | jq -r '.Account'`

aws lambda create-function \
    --function-name "$functionName" \
    --runtime python3.9 \
    --zip-file "fileb://$zipName" \
    --handler "$pyTempName.$pcFuncName" \
    --role "arn:aws:iam::"$accountNumber":role/LabRole" \
    --region $region \
    --layers "$layer" \
    > /dev/null

rm $zipName

#Der Funktion das Recht geben  aud den Bucket zuzugreifen
aws lambda add-permission \
    --function-name $functionName \
    --action lambda:InvokeFunction \
    --statement-id s3 \
    --principal s3.amazonaws.com \
    --source-arn "arn:aws:s3:::$bucket1" \
    > /dev/null
echo "Lambda Funktion \"$functionName\" wurde erstellt"

# #Policy des Buckets erstellen
# policy='{
#     "Version": "2012-10-17",
#     "Id": "ProjectBucketPolicy1",
#     "Statement": [
#         {
#             "Sid": "st1",
#             "Effect": "Allow",
#             "Principal": {
#                 "AWS": "*"
#             },
#             "Action": "s3:*",
#             "Resource": "arn:aws:s3:::'$bucket1'"
#         }
#     ]
# }'
# aws s3api put-bucket-policy --bucket "$bucket1" --policy "$policy" > /dev/null

# Dem Bucket einen Trigger(alle Create Events) hinzufügen und auf die Funktion verweisen 
eventJson='{
    "LambdaFunctionConfigurations": 
    [
        {
            "Id": "'$functionName'",
            "LambdaFunctionArn": "arn:aws:lambda:'$region':'$accountNumber':function:'$functionName'",
            "Events": ["s3:ObjectCreated:*"],
            "Filter": 
            {
                "Key": 
                {
                    "FilterRules": 
                    [
                        {
                            "Name": "prefix",
                            "Value": ""
                        },
                        {
                            "Name": "suffix",
                            "Value": ""
                        }
                    ]
                }
            }
        }
    ]
}'

#Manchmal hat es beim ersten mal nicht funktioniert aber beim zweiten mal schon
if `aws s3api put-bucket-notification-configuration --bucket "$bucket1" --notification-configuration "$eventJson" > /dev/null`
then
:
else
echo "Nochmalsversuchen Policy hinzuzufügen"
    aws s3api put-bucket-notification-configuration --bucket "$bucket1" --notification-configuration "$eventJson" > /dev/null
fi

echo "Notification erstellt"

#Ausgabe und Beispiel
echo ""
echo "Alles fertig eingerichtet"
echo "Bucket orginal: "$bucket1
echo "Bucket verkleinert: "$bucket2
echo ""
filesInTestBildDir=(../Testbild/*)
testBildPfad="${filesInTestBildDir[-1]}"
if [ -z "$testBildPfad" ]
then
    echo "Im \"Testbild-Ordner ist keine Datei\""
    echo "Bitte ein Bild einfügen"
else
    testBildDir="$(dirname "${testBildPfad}")"
    testBildName="$(basename "${testBildPfad}")"
    echo "Beispiel:"
    set -x
    aws s3 cp "$testBildPfad" "s3://$bucket1"
    { set +x; } 2>/dev/null

    sleep 5 # Der Copy-Funktion Zeit geben da sie ein paar Sekunden braucht

    set -x
    if `aws s3 cp "s3://$bucket2/$compressesPrefix$testBildName" "$testBildDir/$compressesPrefix$testBildName" >/dev/null`
    then
    { set +x; } 2>/dev/null

    #Bild wieder von Buckets entfernen
    aws s3 rm "s3://$bucket1/$testBildName" > /dev/null
    aws s3 rm "s3://$bucket2/$compressesPrefix$testBildName" > /dev/null

    echo "Das verkleinerte Bild ist gespeicher unter: $testBildDir/$compressesPrefix$testBildName"
    echo ""
    echo "Erfolg :)"
    else
    { set +x; } 2>/dev/null
    
    #Bild wieder von Buckets entfernen
    aws s3 rm "s3://$bucket1/$testBildName" > /dev/null
    aws s3 rm "s3://$bucket2/$compressesPrefix$testBildName" > /dev/null

    echo ""
    echo "Es ist ein Fehler aufgetreten :("

    # Wieder aufräumen
    aws lambda delete-function --function-name $functionName > /dev/null
    aws s3 rb s3://$bucket1 --force >/dev/null
    aws s3 rb s3://$bucket2 --force >/dev/null
    fi
fi