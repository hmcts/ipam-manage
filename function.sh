#!/bin/bash

# Usage: ./script.sh [get|post|put] <bearer_token> <json_body>

# API endpoint URL
base="https://ipam.hmcts.net"


# Extract arguments
http_method="$1"
bearer_token="$2"
json_body="$3"
api="$4"

url="$base$api"

# Make a GET request
get_request() {
    curl -X GET -H "Authorization: Bearer $bearer_token" "$url"
}

# Make a POST request
post_request() {
    curl -X POST -H "Authorization: Bearer $bearer_token" -H "Content-Type: application/json" -d "$json_body" "$url"
}

# Make a PUT request
put_request() {
    curl -X PUT -H "Authorization: Bearer $bearer_token" -H "Content-Type: application/json" -d "$json_body" "$url"
}

# Make a DELETE request
delete_request() {
    curl -X DELETE -H "Authorization: Bearer $bearer_token" -H "Content-Type: application/json" -d "$json_body" "$url"
}

# Validate arguments
if [[ $# -ne 4 ]]; then
    echo "Usage: $0 [get|post|put|delete] <bearer_token> <json_body> <api>"
    exit 1
fi

# Execute the appropriate request
case "$http_method" in
    get)
        get_request ;;
    post)
        post_request ;;
    put)
        put_request ;;
    delete)
        delete_request ;;
    *)
        echo "Invalid HTTP method. Supported methods: get, post, put, delete" ;;
esac
