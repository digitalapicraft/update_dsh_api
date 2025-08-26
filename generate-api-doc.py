import os
import yaml
from openapi_spec_validator import validate_spec

API_DOC_DIR = 'api_document'


def extract_markdown_from_openapi(openapi_path):
    try:
        with open(openapi_path, 'r') as f:
            spec = yaml.safe_load(f)
    except Exception as e:
        return f"# YAML Loading Error\n\n{e}\n"
    # Validate the spec (optional, can comment out if not needed)
    try:
        validate_spec(spec)
    except Exception as e:
        return f"# OpenAPI Validation Error\n\n{e}\n"
    lines = []
    title = spec.get('info', {}).get('title', 'API Documentation')
    description = spec.get('info', {}).get('description', '')
    version = spec.get('info', {}).get('version', '')
    # Overview section
    lines.append(f"# {title}")
    if version:
        lines.append(f"**Version:** {version}")
    lines.append("\n## Overview")
    # Add a generic, human-friendly overview using the API/service name
    lines.append(f"The **{title} API** provides a set of endpoints to manage resources related to this service. This includes creating, retrieving, updating, and deleting resources as appropriate. This documentation provides detailed information about each endpoint, including request and response formats, authentication, error handling, and usage examples.")
    if description:
        lines.append(f"\n{description.strip()}")
    # Collect endpoints for summary
    paths = spec.get('paths', {})
    endpoint_summaries = []
    for path, methods in paths.items():
        for method, details in methods.items():
            summary = details.get('summary', '')
            endpoint_summaries.append(f"- `{method.upper()} {path}`: {summary if summary else ''}")
    if endpoint_summaries:
        lines.append("\n### Main Endpoints")
        lines.extend(endpoint_summaries)
    # Detailed endpoint documentation
    for path, methods in paths.items():
        for method, details in methods.items():
            summary = details.get('summary', '')
            lines.append(f"\n## `{method.upper()} {path}`")
            if summary:
                lines.append(f"- **Summary:** {summary}")
            if 'parameters' in details:
                lines.append(f"- **Parameters:**")
                for param in details['parameters']:
                    pname = param.get('name', '')
                    pdesc = param.get('description', '')
                    preq = param.get('required', False)
                    ploc = param.get('in', '')
                    lines.append(f"    - `{pname}` ({ploc}, {'required' if preq else 'optional'}): {pdesc}")
            if 'requestBody' in details:
                lines.append(f"- **Request Body:**")
                reqbody = details['requestBody']
                if 'description' in reqbody:
                    lines.append(f"    - {reqbody['description']}")
                content = reqbody.get('content', {})
                for ctype, cval in content.items():
                    example = cval.get('example') or cval.get('examples', {})
                    if example:
                        lines.append(f"    - Content-Type: {ctype}")
                        lines.append('```json')
                        lines.append(str(example))
                        lines.append('```')
            if 'responses' in details:
                lines.append(f"- **Responses:**")
                for code, resp in details['responses'].items():
                    desc = resp.get('description', '')
                    lines.append(f"    - **{code}**: {desc}")
                    content = resp.get('content', {})
                    for ctype, cval in content.items():
                        example = cval.get('example') or cval.get('examples', {})
                        if example:
                            lines.append(f"        - Content-Type: {ctype}")
                            lines.append('```json')
                            lines.append(str(example))
                            lines.append('```')
    return '\n'.join(lines)

def main():
    for root, dirs, files in os.walk(API_DOC_DIR):
        if 'openapi.yaml' in files:
            openapi_path = os.path.join(root, 'openapi.yaml')
            service_dir = os.path.dirname(openapi_path)
            doc_dir = os.path.join(service_dir, '../documentation')
            doc_dir = os.path.abspath(doc_dir)
            os.makedirs(doc_dir, exist_ok=True)
            doc_path = os.path.join(doc_dir, 'documentation.md')
            md_content = extract_markdown_from_openapi(openapi_path)
            with open(doc_path, 'w') as f:
                f.write(md_content)
            print(f"Generated documentation for {openapi_path} -> {doc_path}")

if __name__ == '__main__':
    main()
