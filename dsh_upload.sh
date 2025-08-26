#!/bin/bash

# CONFIG_FILE="dsh-config.json"
API_URL="https://$INPUT_URL/api/v1/digital-content/documentation"
LOGIN_URL="https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}"
USERNAME="${USERNAME}"
PASSWORD="${PASSWORD}"

echo "$API_URL"

# Login and get idToken
login_response=$(curl -s "$LOGIN_URL" \
  -H 'accept: */*' \
  -H 'accept-language: en-GB,en-US;q=0.9,en;q=0.8' \
  -H 'content-type: application/json' \
  -H 'origin: https://osh-preprod.oneapihub.com' \
  -H 'priority: u=1, i' \
  -H 'sec-ch-ua: "Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: cross-site' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36' \
  -H 'x-browser-copyright: Copyright 2025 Google LLC. All rights reserved.' \
  -H 'x-browser-validation: qvLgIVtG4U8GgiRPSI9IJ22mUlI=' \
  -H 'x-browser-year: 2025' \
  -H 'x-client-data: CJO2yQEIo7bJAQipncoBCL78ygEIk6HLAQiko8sBCIagzQEIif3OAQ==' \
  -H 'x-client-version: Chrome/JsCore/10.14.1/FirebaseCore-web' \
  -H 'x-firebase-gmpid: 1:1019068528267:web:8d6fcd35100fb5028c468e' \
  --data-raw '{"returnSecureToken":true,"email":"'$USERNAME'","password":"'$PASSWORD'","clientType":"CLIENT_TYPE_WEB"}')

TOKEN=$(echo "$login_response" | jq -r '.idToken')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo login_response : "$login_response" 
  echo "Failed to obtain Bearer token. Please check your credentials."
  exit 1
fi

# Check jq is installed
if ! command -v jq &> /dev/null; then
  echo "jq is required but not installed. Please install jq."
  exit 1
fi

# Read all keys from config

for key in "$@"; do
  dir="api_document/$key"
  zip_file="${key}.zip"
  api_json="$dir/api.json"

  if [ -d "$dir" ]; then
    echo "📦 Zipping $dir as $zip_file (excluding api.json)"

    (
      cd api_document || exit 1
      zip -r -q "../$zip_file" "$key" -x "$key/api.json"
    )
    # Extract values from JSON
  
  wrapperContentId=$(jq -r '.digitalContentId' "$api_json")
  versionedContentId=$(jq -r '.versionedContentId' "$api_json")
  digitalContentType=$(jq -r '.contentType' "$api_json")
    # Prepare requestModel JSON
    requestModel=$(printf '{"wrapperContentId":"%s","versionedContentId":"%s","digitalContentType":"%s"}' "$wrapperContentId" "$versionedContentId" "$digitalContentType")
    # uncomment for debugging
    # Print the curl command
    # echo "\nAbout to run the following curl command for $dir:"
    # echo "curl -s -o /dev/null -w '%{http_code}' '$API_URL' \\"
    # echo "  -H 'authorization: Bearer <token>' \\"
    # echo "  --form 'zipFile=@$zip_file;type=application/zip' \\"
    # echo "  --form 'requestModel=$requestModel'"
    
    # Perform curl upload using --form
    response=$(curl -s "$API_URL" \
      -H "authorization: Bearer $TOKEN" \
      --form "zipFile=@$zip_file;type=application/zip" \
      --form "requestModel=$requestModel")    
    status_code=$(echo "$response" | jq -r '.status_code // empty')
    if [ -n "$status_code" ] && [ -z "$status_code" ] && [ "$status_code" -gt 399 ]; then
      echo "Upload failed for $dir (status_code $status_code)"
    else
      echo "$status_code"
      echo "Upload succeeded for $dir"
    fi
    # uncomment for debugging
    # echo response : "$response"
    # read -p "Press Enter to continue"
    rm -f "$zip_file"
  else
    echo "Directory missing: $dir"
    missing_dirs+=("$dir")
  fi
done

if [ ${#missing_dirs[@]} -ne 0 ]; then
  echo "\nMissing directories:"
  for d in "${missing_dirs[@]}"; do
    echo "- $d"
  done
fi 
