#!/usr/bin/env bash
curl -X POST \
  -H "X-Parse-Application-Id: Silk" \
  -H "X-Parse-Master-Key: abcd12345678" \
  -H "Content-Type: application/json" \
  -d '{"plan":"paid"}' \
  https://127.0.0.1:1337/parse/jobs/getVideos