#!/bin/bash

# Script to generate dsh-config.json from the search API

# User credentials (replace with env vars or your actual credentials)
USERNAME="${USERNAME}"
PASSWORD="${PASSWORD}"
LOGIN_URL="https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}"

# Obtain Bearer token
login_response=$(curl -s "$LOGIN_URL" \
  -H 'content-type: application/json' \
  --data-raw '{"returnSecureToken":true,"email":"'$USERNAME'","password":"'$PASSWORD'","clientType":"CLIENT_TYPE_WEB"}')

TOKEN=$(echo "$login_response" | jq -r '.idToken')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo "Failed to obtain Bearer token. Please check your credentials."
  exit 1
fi

SEARCH_URL="https://healthifyme-pov-2.digitalapicraft.com/api/v1/digital-content/page"
SEARCH_PAYLOAD='{"visibilities":["ALL","NONE","INTERNAL","EXTERNAL","PUBLIC"],"page":0,"limit":200,"contentTypes":["API"],"gatewayInstanceIds":[],"gatewayTypes":[],"loggedInUserEmail":"","businessAreaIds":["6889d7d5425aa40e67835ea0"]}'


# Call the search API
search_response=$(curl -s "$SEARCH_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data-raw "$SEARCH_PAYLOAD")

# Make sure base directory exists
mkdir -p api_document

# Parse each API and write to its own api.json
echo "$search_response" | jq -c '.data.pagedData[]' | while read -r api; do
  api_name=$(echo "$api" | jq -r '.name')
  safe_api_name=$(echo "$api_name" | tr -cd '[:alnum:]_-' | tr ' ' '_')  # Sanitize folder name

  digitalContentId=$(echo "$api" | jq -r '.id')
  versionedContentId=$(echo "$api" | jq -r '.versions[-1].versionedContentId')
  contentType=$(echo "$api" | jq -r '.contentType')
  version=$(echo "$api" | jq -r '.versions[-1].version')
  userFriendlyDescription=$(echo "$api" | jq -r '.versions[-1].userFriendlyDescription')
  technicalName=$(echo "$api" | jq -r '.versions[-1].technicalName')

  # Create directory and write api.json
  mkdir -p "api_document/$safe_api_name"

  cat > "api_document/$safe_api_name/api.json" <<EOF
{
  "digitalContentId": "$digitalContentId",
  "versionedContentId": "$versionedContentId",
  "contentType": "$contentType",
  "apiName": "$api_name",
  "version": "$version",
  "userFriendlyDescription": "$userFriendlyDescription",
  "technicalName": "$technicalName"
}
EOF
done

echo "All individual API JSON files have been generated in api_document/."
