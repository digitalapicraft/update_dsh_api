#!/bin/bash

set -e
set -o pipefail

# ---------- 🔐 Configurable (ideally use GitHub Secrets or env vars) ----------
USERNAME="${USERNAME}"
PASSWORD="${PASSWORD}"
API_KEY="${POSTMAN_API_KEY}"
BA_ID="6889d7d5425aa40e67835ea0"  # Dummy or dynamic value
LOGIN_URL="https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}"

FIRST_API_URL="https://healthifyme-pov-2.digitalapicraft.com/api/v1/postman/collections"
SECOND_API_URL="https://healthifyme-pov-2.digitalapicraft.com/api/v1/postman/collections/submit-import-task"
STATUS_API_URL="https://healthifyme-pov-2.digitalapicraft.com/api/v1/tasks"

# ---------- 🔐 Step 1: Login to Firebase and extract idToken ----------
login_response=$(curl -s "$LOGIN_URL" \
  -H "Content-Type: application/json" \
  --data-raw '{
    "returnSecureToken": true,
    "email": "'"$USERNAME"'",
    "password": "'"$PASSWORD"'",
    "clientType": "CLIENT_TYPE_WEB"
  }')

# Extract token safely
TOKEN=$(echo "$login_response" | jq -r '.idToken')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Login failed. Check USERNAME/PASSWORD or Firebase API key."
  exit 1
fi

echo "✅ Logged in. Token acquired."




# ---------- 📥 Step 2: Call First API with Bearer Token ----------
SEARCH_PAYLOAD="{\"apiKey\": \"$API_KEY\"}"
response=$(curl -s -X POST "$FIRST_API_URL" \
  -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
  --data-raw "$SEARCH_PAYLOAD")

if ! echo "$response" | jq -e '.data' > /dev/null 2>&1; then
  echo "❌ First API call failed or returned invalid response:"
  echo "$response" 
 
  exit 1
fi  
echo "✅ First API call successful."




# ---------- 📤 Step 3: Extract 'existing: false' items ----------
filtered_items=$(jq -c '[.data[] | select(.existingApi == false)]' <<< "$response")
# If empty, skip sending second request
if ! echo "$response" | jq -e 'type == "object" and .data and (.data | type == "array")' > /dev/null 2>&1; then
  echo "❌ First API call failed or returned invalid structure:"
  echo "$response" | jq '.' || echo "$response"
  exit 1
fi
updated_collection=$(echo "$filtered_items" | jq 'map(. + {checkout: true})')
# echo "$updated_collection" 





# ---------- 🚀 Step 4: Build and send payload to second API ----------
payload="{\"apiKey\": \"$API_KEY\", \"businessAreaId\": \"$BA_ID\", \"collections\": $updated_collection}"

# echo "$payload"   

second_response=$(curl -s -X POST "$SECOND_API_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data-raw "$payload")






# ---------- ✅ Step 5: Print Result Safely ----------
echo "✅ Second API responded:"
# echo "$second_response"





# ---------- ✅ Step 6: GET request ----------
taskId=$(echo "$second_response" | jq -r '.data')

# echo "Extracted Task ID: $taskId"

# Now send the GET request using taskId
status_response=$(curl -s -X GET "$STATUS_API_URL/$taskId" \
  -H "Authorization: Bearer $TOKEN")

# Output result
# echo "$status_response"














