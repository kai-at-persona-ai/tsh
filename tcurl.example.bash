#!/bin/bash

# Dependencies:
# apt install -y jq # jq for json manipulation
# apt install -y curl

# imports:
. ./tcurl.bash --source-only
# example
tcurl https://jsonplaceholder.typicode.com/users/1
tcurl curl jq https://jsonplaceholder.typicode.com/users/1
echo $(tcurl curl jq https://jsonplaceholder.typicode.com/users/1) | jq -r '.data'
echo $(tcurl curl jq "${ELASTICSEARCH_URL}/_cat/health?format=json") | jq -r '.data'
tcurl curl jq httpss://jsonplaceholder.typicode.com/users/1

# tcurl curl jq "${ELASTICSEARCH_URL}/_cat/health?format=json"