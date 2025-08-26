import os
import yaml
import sys
from openapi_spec_validator import validate_spec

API_DOC_DIR = 'Api_Document'


def sanity_check_openapi(openapi_path):
    errors = []
    try:
        with open(openapi_path, 'r') as f:
            spec = yaml.safe_load(f)
    except Exception as e:
        errors.append(f"YAML Loading Error: {e}")
        return errors
    # Basic required fields
    info = spec.get('info', {})
    if not info.get('title'):
        errors.append('Missing info.title')
    if not info.get('version'):
        errors.append('Missing info.version')
    if not spec.get('paths'):
        errors.append('Missing paths')
    # Validate with openapi_spec_validator
    try:
        validate_spec(spec)
    except Exception as e:
        errors.append(f"OpenAPI Validation Error: {e}")
    return errors

def main():
    failed = []
    changed_folders = sys.argv[1:]
    for root in changed_folders:
        if 'openapi.yaml' in files:
            openapi_path = os.path.join(root, 'openapi.yaml')
            errors = sanity_check_openapi(openapi_path)
            if errors:
                failed.append((openapi_path, errors))
                print(f"[FAIL] {openapi_path}")
                for err in errors:
                    print(f"    - {err}")
            else:
                print(f"[PASS] {openapi_path}")
    print(f"\nSanity check complete. {len(failed)} contract(s) failed.")
    if failed:
        print("\nSummary of failures:")
        for path, errs in failed:
            print(f"- {path}")
            for err in errs:
                print(f"    - {err}")

if __name__ == '__main__':
    main()
