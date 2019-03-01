#!/usr/bin/env bash
 #所有订阅
 curl -X GET \
 -H "X-Parse-Application-Id: Silk" \
 -G \
 --data-urlencode 'where={"follows":{"__type":"Pointer","className":"User","objectId":"KyDkqBmKLU"}}' \
 http://47.94.98.55:1337/parse/classes/Author

