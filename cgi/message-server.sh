#!/bin/bash

# based on https://github.com/ruudud/cgi

TWILIO_MSG_SERVICE_SID="INSERT YOUR MESSAGE SERVICE SID HERE"
MESSAGE_FETCH_KEY="ADD A RANDOM SHARED SECRET HERE"

# httputils creates the associative arrays POST_PARAMS and GET_PARAMS
if [[ "$SCRIPT_FILENAME" ]]; then
  . "$(dirname $SCRIPT_FILENAME)/httputils"
else
  . "$(dirname $(pwd)$SCRIPT_NAME)/httputils"
fi


do_POST() {
  if [ "${POST_PARAMS['MessagingServiceSid']}" == "$TWILIO_MSG_SERVICE_SID" ]; then
    MESSAGE=${POST_PARAMS['Body']}
    printf "%s\n" "$MESSAGE" | sed -e 's/+/ /g; s/%/\\x/g' | xargs -0 printf > /tmp/last-message
    echo "Status: 200 OK"
    echo "Content-type: text/html"
    echo ""
    echo "<Response></Response>"
  elif [ "${POST_PARAMS['FetchKey']}" == "$MESSAGE_FETCH_KEY" ]; then
    echo "Status: 200 OK"
    echo "Content-type: text/plain"
    echo ""
    cat /tmp/last-message
    echo "" > /tmp/last-message
  else
    echo "Status: 403 Unauthorized"
    echo "Content-type: text/html"
    echo ""
    echo "<Response></Response>"
  fi
}

do_GET() {
  echo "Status: 405 Method Not Allowed"
  echo "Content-type: text/html"
  echo ""
  echo "<Response></Response>"
}


case $REQUEST_METHOD in
  POST)
    do_POST
    ;;
  GET)
    do_GET
    ;;
  *)
    echo "No handle for $REQUEST_METHOD"
    exit 0
    ;;
esac
