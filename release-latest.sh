#!/bin/bash
set -x
CURL_RETRIES="--connect-timeout 60 --retry 5 --retry-delay 5"

# Delete assets
asset_id=($(curl -u $GITHUB_ACTOR:$GH_TOKEN $CURL_RETRIES \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/tags/latest \
| jq -r '.assets[] | select(.name | contains("'"$1"'")) | .id' | tr -d '\r'))

for id in "${asset_id[@]}"; do
  curl -u $GITHUB_ACTOR:$GH_TOKEN $CURL_RETRIES \
    -X DELETE \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/assets/$id;
done    

# Release assets
curl -u $GITHUB_ACTOR:$GH_TOKEN $CURL_RETRIES \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/${GITHUB_REPOSITORY}/releases \
  -d '{"tag_name": "latest"}'
  
release_id=$(curl -u $GITHUB_ACTOR:$GH_TOKEN $CURL_RETRIES \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/tags/latest | jq -r '.id')
  
for f in $2/*.xz; do 
  curl -u $GITHUB_ACTOR:$GH_TOKEN $CURL_RETRIES \
    -X POST -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: $(file -b --mime-type $f)" \
    https://uploads.github.com/repos/${GITHUB_REPOSITORY}/releases/$release_id/assets?name=$(basename $f) \
    --data-binary @$f; 
done
