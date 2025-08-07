import json
import os
import requests
import glob
import re

INPUT_DIR = "JSON"  # Current directory - change this to your JSON files directory
OUTPUT_FOLDER = "Split_Collections_Flat"
POSTMAN_API_KEY = os.getenv("POSTMAN_API_KEY")
WORKSPACE_ID = os.getenv("POSTMAN_WORKSPACE_ID")

os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# Get all JSON files in the input directory
json_files = glob.glob(os.path.join(INPUT_DIR, "*.json"))


def to_pascal_preserve_hyphen(name):
    parts = name.split('-')
    pascal_parts = [''.join(word.capitalize() for word in re.split(r'\s+|/', part)) for part in parts]
    return '-'.join(pascal_parts)

for input_file in json_files:
    # Skip the output folder and any existing split files
    if "Split_Collections_Flat" in input_file or input_file.endswith("_split.json"):
        continue
        
    print(f"📁 Processing: {input_file}")
    
    # Extract the base filename without extension for prefix
    base_filename = os.path.splitext(os.path.basename(input_file))[0]
    
    with open(input_file, "r", encoding="utf-8") as f:
        original = json.load(f)

    for folder in original["item"]:
        folder_name = folder["name"]
        # Add the source filename as prefix
        prefixed_name = f"{base_filename}-{folder_name}"
        prefixed_name = to_pascal_preserve_hyphen(prefixed_name)
        
        flat_collection = {
            "info": {
                "name": prefixed_name,
                "schema": original["info"]["schema"]
            },
            "item": folder.get("item", [])
        }

        
        output_path = os.path.join(OUTPUT_FOLDER, f"{prefixed_name}.json")
        with open(output_path, "w", encoding="utf-8") as out_file:
            json.dump(flat_collection, out_file, indent=2)

        print(f"✅ Created: {output_path}")

        # Upload to Postman
        headers = {
            "X-Api-Key": POSTMAN_API_KEY,
            "Content-Type": "application/json"
        }
        with open(output_path, "r", encoding="utf-8") as f:
            payload = {
                "collection": json.load(f),
                "workspace": WORKSPACE_ID
            }
            res = requests.post("https://api.getpostman.com/collections", headers=headers, json=payload)
            if res.status_code == 200:
                print(f"✅ Uploaded: {prefixed_name}")
            else:
                print(f"❌ Failed to upload {prefixed_name}: {res.status_code}, {res.text}")

print(" Processing complete!")
