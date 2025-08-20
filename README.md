# update_dsh_api

Here’s a summary of what each script in your project does, which will be used to generate a comprehensive `README.md`:

---

**Project: `update_dsh_api`**

This project provides a set of scripts and utilities for managing API documentation, collections, and content for a Postman-based workflow, including authentication, downloading, uploading, and generating documentation from OpenAPI specs.

### Contents



- **postman_col_up.py**:  
  Processes Postman collection JSON files, extract's api collection, and uploads each split collection to Postman using the Postman API. Requires `POSTMAN_API_KEY` and `POSTMAN_WORKSPACE_ID` environment variables.

- **api_imp.sh**:  
  Authenticates with Firebase, fetches API collections from postman, filters for new APIs, and submits them for import. It also checks the status of import tasks.

- **get_api_id.sh**:  
  Authenticates and queries the API content search endpoint were mainly GET all api content and version id from respective business area, generating a `api.json` metadata file for each API in the `Api_Document` directory.  

- **download_doc.sh**:  
  Authenticates and downloads documentation ZIP files for each API(documentation,metadata,contract), extracts them, and places the contents in the appropriate directories(Api_Document).

- **generate-api-doc.py**:  
  Extracts and generates Markdown documentation from OpenAPI spec files found in the `Api_Document` directory for each api.

- **dsh_upload.sh**:  
  Authenticates and uploads zipped API documentation to a remote server. It reads metadata from each API's `api.json` and uploads the corresponding ZIP file this get tigger once we change documentation files.

- **sanity_check_openapi.py**:  
  It validates contract for openapi 2 and 3 were it runs along with coustom git action while uploading the document into preprod.  



---

### Example Usage

#### 1. Environment Setup

Set the following environment variables (e.g., in your shell or CI/CD secrets):

```sh
export USERNAME="your-email@example.com"
export PASSWORD="your-password"
export POSTMAN_API_KEY="your-postman-api-key"
export POSTMAN_WORKSPACE_ID="your-postman-workspace-id"
export FIREBASE_API_KEY="your-firebase-api-key"
```

also you can change `bussinessAreaid`
#### 2. Process and Upload Postman Collections

```sh
python3 postman_col_up.py
```

#### 3. Import APIs into pre-prod

```sh
./api_imp.sh
```

#### 4. Download API Metadata

```sh
./get_api_id.sh
```

#### 5. Download Documentation

```sh
./download_doc.sh
```

#### 6. Generate Markdown Document

```sh
python3 generate-api-doc.py
```



#### 7. Upload Documentation as zip file(Document,metadata,contract)

just use the action.yml work flow

---

### Requirements

- Python 3.x
- `openapi-spec-validator`, `pyyaml`, `requests` (for Python scripts)
- `jq`, `curl`, `zip`, `unzip` (for shell scripts)
- Access to the relevant API endpoints and credentials

---

### Notes

- All scripts assume the presence of the `Api_Document` directory and proper API credentials.
- Sensitive information should be managed via environment variables or secret managers.
- Also make sure that your api collection file is in `JSON` folder 
- All the script and python files are in root folder
- While using the coustom action make sure to add 
    "- name: Run custom GitHub Action
        uses: digitalapicraft/update_dsh_api@main
        env:
          USERNAME: ${{ env.USERNAME }}
          PASSWORD: ${{ env.PASSWORD }}
          FIREBASE_API_KEY: ${{ env.FIREBASE_API_KEY }}" in your workflow.
- once you done this setup no need to run the script unless you add new api.
- if you update any documentation you can run the workflow mannually and only the `changed doc get updated `         
- For more details, review each script’s comments and code.

---

