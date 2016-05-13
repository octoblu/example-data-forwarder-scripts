#!/usr/bin/env bash

SERVICE_URL=$1

if [ -z "$SERVICE_URL" ]; then
   echo "usage: ./example-data-forwarder.sh <SERVICE_URL>"
   exit 1;
fi


mkdir ./tmp

echo "creating Endoskeleton device"
meshblu-util register -d '{"type": "endoskeleton"}' > ./tmp/endoskeleton-meshblu.json
ENDOSKELETON_UUID=$(cat ./tmp/endoskeleton-meshblu.json | jq -r '.uuid')
ENDOSKELETON_TOKEN=$(cat ./tmp/endoskeleton-meshblu.json | jq -r '.token')
echo "endoskeleton is: $ENDOSKELETON_UUID"


echo "creating Doorbell device"
meshblu-util register -d '{"type": "doorbell"}' > ./tmp/doorbell-meshblu.json
DOORBELL_UUID=$(cat ./tmp/doorbell-meshblu.json | jq -r '.uuid')
DOORBELL_TOKEN=$(cat ./tmp/doorbell-meshblu.json | jq -r '.token')
echo "doorbell is: $DOORBELL_UUID"

echo "adding Doorbell to Endoskeleton's message.from whitelist"
meshblu-util update -p -d "{\"\$addToSet\": {\"meshblu.whitelists.message.from\": {\"uuid\": \"$DOORBELL_UUID\"}}}" ./tmp/endoskeleton-meshblu.json

echo "creating Forwarder device"
meshblu-util register -d '{"type": "forwarder"}' > ./tmp/forwarder-meshblu.json
FORWARDER_UUID=$(cat ./tmp/forwarder-meshblu.json | jq -r '.uuid')
FORWARDER_TOKEN=$(cat ./tmp/forwarder-meshblu.json | jq -r '.token')
echo "forwarder is: $FORWARDER_UUID"

echo "adding webhook to forwarder"
meshblu-util create-hook -t message.received -U $SERVICE_URL ./tmp/forwarder-meshblu.json

echo "adding forwarder to Endoskeleton's message.received whitelist"
meshblu-util update -p -d "{\"\$addToSet\": {\"meshblu.whitelists.message.received\": {\"uuid\": \"$FORWARDER_UUID\"}}}" ./tmp/endoskeleton-meshblu.json


echo "Subscribing Forwarder to it's own messages"
meshblu-util subscription-create -e $FORWARDER_UUID -s $FORWARDER_UUID -t message.received ./tmp/forwarder-meshblu.json

echo "Subscribing Forwarder to Endoskeleton's received messages"
meshblu-util subscription-create -e $ENDOSKELETON_UUID -s $FORWARDER_UUID -t message.received ./tmp/forwarder-meshblu.json
