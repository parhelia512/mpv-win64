#!/bin/bash

GH_TOKEN=(${{ secrets.BOT }})
CURL_RETRIES=("--connect-timeout 60 --retry 999 --retry-delay 5")

# Delete assets
asset_id=$(curl -u $GITHUB_ACTOR:"${GH_TOKEN[@]}" "${CURL_RETRIES[@]}" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/${{ github.repository }}/releases/tags/dev \
  | jq -r '.assets[] | select(.name | startswith("$1")) | .id')                        
curl -u $GITHUB_ACTOR:${GH_TOKEN[@]}" $CURL_RETRIES \
  -X DELETE \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/${{ github.repository }}/releases/assets/$asset_id    

# Release assets
curl -u $GITHUB_ACTOR:"${GH_TOKEN[@]}" "${CURL_RETRIES[@]}" \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/${{ github.repository }}/releases \
  -d '{"tag_name": "dev"}'
  release_id=$(curl -u $GITHUB_ACTOR:"${GH_TOKEN[@]}" "${CURL_RETRIES[@]}" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/${{ github.repository }}/releases/tags/dev | jq -r '.id')
  for f in $2/*.zst; do 
    curl -u $GITHUB_ACTOR:"${GH_TOKEN[@]}" "${CURL_RETRIES[@]}" \
      -X POST -H "Accept: application/vnd.github.v3+json" \
      -H "Content-Type: $(file -b --mime-type $f)" \
      https://uploads.github.com/repos/${{ github.repository }}/releases/$release_id/assets?name=$(basename $f) --data-binary @$f; 
  done
