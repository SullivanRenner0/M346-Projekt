#!/bin/bash

#nötiges installieren 
echo " "
echo "Packages werden vorbereitet ..."
sudo apt-get -qq update > /dev/null
sudo apt-get install -qq zip > /dev/null
sudo apt-get install -qq jq > /dev/null
echo "Packages wurden fertig vorbereitet"

#Variabeln deklarieren
export bucket1o="sr-lg-m346-projekt-original"
export bucket2o="sr-lg-m346-projekt-compressed"
export bucket1=""
export bucket2=""
export functionNameo="copyImage"
export functionName=""
export zipName="lambda.zip"
export funcLayer="arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p39-pillow:1" #PIL - Image
export compressesPrefix="resized_"
export py="index.py"
export pyTempName="CopyImage"
export pyTemp="$pyTempName.py"
export accountNumber=''
export policy=''
export eventJson=''
export testBildName=''
export testBildDir=''
export filesInTestBildDir=''

#Einzigartige Namen für die Buckets und die Funktion finden
bucket1=$bucket1o
bucket2=$bucket2o
functionName=$functionNameo
export i=0
while `aws s3api head-bucket --bucket $bucket1 2>/dev/null || aws s3api head-bucket --bucket $bucket2 2>/dev/null || aws lambda get-function --function-name $functionName 2>/dev/null`
do
i=$((i+1))
bucket1="$bucket1o-$i"
bucket2="$bucket2o-$i"
functionName=$functionNameo"_"$i
done

#Buckets erstellen
echo ""
aws s3 mb s3://$bucket1 > /dev/null
echo "Bucket \"$bucket1\" wurde erstellt"
aws s3 mb s3://$bucket2 > /dev/null
echo "Bucket \"$bucket2\" wurde erstellt"

#Funktion erstellen
cp $py $pyTemp > /dev/null
sed -i -e 's/sourcebucket_replace/'$bucket1'/g' $pyTemp
sed -i -e 's/destbucket_replace/'$bucket2'/g' $pyTemp
sed -i -e 's/resizedPrefix_replace/'$compressesPrefix'/g' $pyTemp
zip -r9 $zipName $pyTemp > /dev/null
rm $pyTemp
accountNumber=`aws sts get-caller-identity | jq -r '.Account'`
aws lambda create-function --function-name "$functionName" --runtime python3.9 --zip-file "fileb://$zipName" --handler "$pyTempName.lambda_handler" --role "arn:aws:iam::"$accountNumber":role/LabRole" --region us-east-1 --layers "$funcLayer" > /dev/null
rm $zipName

#Der Funktion das Recht geben  aud den Bucket zuzugreifen
aws lambda add-permission --function-name $functionName --action lambda:InvokeFunction --statement-id s3 --principal s3.amazonaws.com --source-arn "arn:aws:s3:::$bucket1" --output text > /dev/null

echo "Lambda Funktion \"$functionName\" wurde erstellt"

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

#Dem Bucket einen Trigger(alle Create Events) hinzufügen und auf die Funktion verweisen 
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
    sleep 5 # Der Copy-Funktion zeit geben da sie ein paar Sekunden braucht
    set -x
    if `aws s3 cp "s3://$bucket2/$compressesPrefix$testBildName" "$testBildDir/$compressesPrefix$testBildName" >/dev/null`
    then
    { set +x; } 2>/dev/null

    #Bild wieder von Buckets entfernen
    aws s3 rm "s3://$bucket1/$testBildName" > /dev/null
    aws s3 rm "s3://$bucket2/$compressesPrefix$testBildName" > /dev/null

    echo ""
    echo "Das verkleinerte Bild ist gespeicher unter: $testBildDir/$compressesPrefix$testBildName"
    echo "Erfolg :)"
    else
    { set +x; } 2>/dev/null
    
    #Bild wieder von Buckets entfernen
    aws s3 rm "s3://$bucket1/$testBildName" > /dev/null
    aws s3 rm "s3://$bucket2/$compressesPrefix$testBildName" > /dev/null

    echo ""
    echo "Es ist ein Fehler aufgetreten :("

    fi
fi