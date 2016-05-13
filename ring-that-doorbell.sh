#!/usr/bin/env bash


echo "Ringing that doorbell!"
ENDOSKELETON_UUID=$(cat ./tmp/endoskeleton-meshblu.json | jq -r '.uuid')

meshblu-util message -d \
"{\"devices\": [\"$ENDOSKELETON_UUID\"], \"payload\": \"Hey, Endoskeleton. Somebody's at the door. Do something about it.\"}" \
./tmp/doorbell-meshblu.json
