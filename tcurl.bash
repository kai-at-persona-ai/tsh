#!/bin/bash
set -Euo pipefail

# curl wrapper, force all curl request to returns with status code and error message instead of silent panic
function tcurl() {

    local x_curl
    x_curl="$1"
    if [[ $x_curl = "curl" ]]; then
        shift
    else
        x_curl=curl # asume curl is installed
    fi

    local x_jq
    x_jq="$1"
    if [[ $x_jq = "jq" ]]; then
        shift
    else
        x_jq=jq # asume curl is installed
    fi
    local headerfile
    headerfile=$(mktemp)
    local response
    response="[$(
        "$x_curl" \
            -s \
            -D "$headerfile" \
            --fail-with-body \
            -w ',%{json},"%header{Content-Type}"]' \
            "$@"
    )"
    response=${response/"[,"/"[null,"}
    local response_data
    response_data=$(echo "$response" | $x_jq -r)
    if [ ! "$response_data" ]; then
        echo -e "$response"
        echo "[TCURL: Error 1] Response must be json"
        echo "$(echo "${response}" | head -1)...]"
        exit 2

    fi
    local details
    details=$(echo "$response_data" | $x_jq -r '.[1]')
    local content_type
    content_type=$(echo "$response_data" | $x_jq -r '.[2]')
    local data

    # check for 'json' in content_type (case insensitive):
    if [[ ! "${content_type,,}" == *"json"* ]]; then
        echo "[TCURL: Error 2] Response must be json"
        echo "response content_type:$content_type"
    fi
    data=$(echo "$response_data" | $x_jq -r '.[0]')

    local errormsg
    errormsg=$(echo "$details" | $x_jq -r '.errormsg' )
    # echo "errormsg $errormsg"
    if [ "$errormsg" = null ]; then
        errormsg="\"\""
    else
        errormsg=$(echo "$errormsg" | $x_jq -Rsa '.' )
    fi   
    

    local status_code
    status_code=$(echo "$details" | $x_jq -r '.http_code')
    local headerstring
    headerstring=$(<"$headerfile") 

    if [[ "$headerstring" && "$headerstring" != "\n" ]]; then
        headerstring=$(echo  "$headerstring" | jq -r --raw-input --slurp 'split("\r\n") |  map(select(length > 0)) ' )
    else  
        headerstring="[]"
    fi

    local json_output
     json_output=$(
        echo -e '{ 
            "status_code": null,
            "error_message": null,
            "headers": null,
            "details": null,
            "data": null
        }' | \
        $x_jq -r "$(printf '.status_code=%s' "$status_code")" | \
        $x_jq -r "$(printf '.error_message=%s' "$errormsg")" | \
        $x_jq -r "$(printf '.headers=%s' "$headerstring")" | \
        $x_jq -r "$(printf '.details=%s' "$details")" | \
        $x_jq -r "$(printf '.data=%s' "$data")" 
        
    )
    echo "$json_output" | $x_jq -r
}
