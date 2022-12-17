#!/bin/bash

#nötiges installieren 
echo " "
echo "Packages werden vorbereitet ..."
sudo apt-get -qq update > /dev/null
sudo apt-get install -qq zip > /dev/null
sudo apt-get install -qq jq > /dev/null
echo "Packages wurden fertig vorbereitet"

#Variabeln deklarieren
export bucket1=sr-lg-m346-projekt-source-2
export bucket2=sr-lg-m346-projekt-compressed-2
export functionName=copyImage2
export zipName=lambda.zip
export funcLayer="arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p39-pillow:1" #PIL - Image
export compressesPrefix="resized_"
export py="index.py"
export pyTemp="CopyImage.py"
export pyTempName="CopyImage"
export accountNumber=''
export policy=''
export eventJson=''
export testBildName=''
export testBildDir=''
export filesInTestBildDir=''



#Buckets löschen
aws s3 rb s3://$bucket1 --force > /dev/null
aws s3 rb s3://$bucket2 --force > /dev/null

#Buckets erstellen
echo ""
aws s3 mb s3://$bucket1 > /dev/null
echo "Bucket \"$bucket1\" wurde erstellt"
aws s3 mb s3://$bucket2 > /dev/null
echo "Bucket \"$bucket2\" wurde erstellt"

#Funktion löschen
aws lambda delete-function --function-name $functionName > /dev/null

#Funktion erstellen
cp $py $pyTemp > /dev/null
sed -i -e 's/sourcebucket_replace/'$bucket1'/g' $pyTemp
sed -i -e 's/destbucket_replace/'$bucket2'/g' $pyTemp
sed -i -e 's/resizedPrefix_replace/'$compressesPrefix'/g' $pyTemp
zip -r9 $zipName $pyTemp > /dev/null
rm $pyTemp
accountNumber=`aws sts get-caller-identity | jq -r '.Account'`
aws lambda create-function --function-name "$functionName" --runtime python3.9 --zip-file "fileb://$zipName" --handler "$pyTempName.lambda_handler" --role "arn:aws:iam::"$accountNumber":role/LabRole" --region us-east-1 --layers "$funcLayer" > /dev/null
echo "Lambda Funktion \"$functionName\" wurde erstellt"
rm $zipName

#Der Funktion das Recht geben  aud den Bucket zuzugreifen
aws lambda add-permission --function-name $functionName --action lambda:InvokeFunction --statement-id s3 --principal s3.amazonaws.com --source-arn "arn:aws:s3:::$bucket1" --output text > /dev/null

#Policy des Buckets erstellen
policy='{
    "Version": "2012-10-17",
    "Id": "ProjectBucketPolicy1",
    "Statement": [
        {
            "Sid": "st1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::'$accountNumber':role/LabRole"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::'$bucket1'"
        }
    ]
}'
aws s3api put-bucket-policy --bucket "$bucket1" --policy "$policy" > /dev/null

#Dem Bucket einen Trigger(alle Create Evente) hinzufügen und auf die Funktion verweisen 
eventJson='{
    "LambdaFunctionConfigurations": 
    [
        {
            "Id": "'$functionName'",
            "LambdaFunctionArn": "arn:aws:lambda:us-east-1:'$accountNumber':function:'$functionName'",
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
aws s3api put-bucket-notification-configuration --bucket "$bucket1" --notification-configuration "$eventJson" > /dev/null

#Ausgabe und Beispiel
echo ""
echo "Alles fertig eingerichtet"
echo ""
filesInTestBildDir=(../Testbild/*)
testBildPfad="${filesInTestBildDir[0]}"
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
    sleep 5 # Der Copy-Funktion zeit geben da sie ein paar Sekunden braucht
    set -x
    aws s3 cp "s3://$bucket2/$compressesPrefix$testBildName" "$testBildDir/$compressesPrefix$testBildName"
    { set +x; } 2>/dev/null

    echo ""
    echo "Erfolg :)"
    echo "Das verkleinerte Bild ist gespeicher unter: $testBildDir/$compressesPrefix$testBildName"
fi