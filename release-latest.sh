#!/bin/bash
set -x
CURL=./bin/curl

# Delete assets
asset_id=($($CURL -u $GITHUB_ACTOR:$GH_TOKEN $CURL_RETRIES \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/tags/latest \
| jq -r '.assets[] | select(.name | startswith("'"$1"'")) | .id' | tr -d '\r'))

for id in "${asset_id[@]}"; do
  $CURL -u $GITHUB_ACTOR:$GH_TOKEN $CURL_RETRIES \
    -X DELETE \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/assets/$id;
done    

# Release assets
$CURL -u $GITHUB_ACTOR:$GH_TOKEN $CURL_RETRIES \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/${GITHUB_REPOSITORY}/releases \
  -d '{"tag_name": "latest"}'
  
release_id=$($CURL -u $GITHUB_ACTOR:$GH_TOKEN $CURL_RETRIES \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/tags/latest | jq -r '.id')
  
for f in $2/*.xz; do 
  $CURL -u $GITHUB_ACTOR:$GH_TOKEN $CURL_RETRIES \
    -X POST -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: $(file -b --mime-type $f)" \
    https://uploads.github.com/repos/${GITHUB_REPOSITORY}/releases/$release_id/assets?name=$(basename $f) \
    --data-binary @$f; 
done
