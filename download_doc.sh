#!/bin/bash

# Usage: ./dsh_download.sh
# Downloads and extracts all contents for each API.

# User credentials
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



BASE_URL="https://healthifyme-pov-2.digitalapicraft.com/api/v1/digital-content/documentation?filePath=gs://healthifyme-pov-2-digital-content"

for api_json_path in Api_Document/*/api.json; do
  # Extract directory and API name
  api_dir=$(dirname "$api_json_path")
  api_name=$(basename "$api_dir")

  # Read versionedContentId from each api.json
  versionedContentId=$(jq -r '.versionedContentId' "$api_json_path")
  DOWNLOAD_URL="${BASE_URL}/${versionedContentId}/zip/documentation.zip"

  ZIP_FILE="${api_name}.zip"
  UNZIP_DIR="${api_name}_Unzipped"

  echo "Downloading $api_name from $DOWNLOAD_URL..."

  # Download the base64 JSON response
  curl -s -L -H "Authorization: Bearer $TOKEN" "$DOWNLOAD_URL" -o "${api_name}.json"

  # Decode and write ZIP
  jq -r '.data.fileContent' "${api_name}.json" | base64 -d > "$ZIP_FILE"

  if [ -f "$ZIP_FILE" ]; then
    if unzip -tq "$ZIP_FILE" > /dev/null; then
      echo "Extracting $ZIP_FILE to $UNZIP_DIR..."
      mkdir -p "$UNZIP_DIR"
      unzip -o "$ZIP_FILE" -d "$UNZIP_DIR"

      echo "Moving extracted contents to $api_dir ..."
      mv "$UNZIP_DIR"/* "$api_dir"/

      # Clean up
      rm -rf "$ZIP_FILE" "${api_name}.json" "$UNZIP_DIR"
      echo "✅ Done for $api_name"
    else
      echo "❌ Invalid ZIP for $api_name. Skipping..."
      head "$ZIP_FILE"
      rm -f "$ZIP_FILE" "${api_name}.json"
    fi
  else
    echo "❌ Failed to download ZIP for $api_name"
    rm -f "${api_name}.json"
  fi
done
