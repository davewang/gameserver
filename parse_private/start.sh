#!/usr/bin/env bash
export MASTER_KEY=abcd12345678
export APP_ID=Silk
export APP_NAME=Silk
export SERVER_URL=http://localhost:1338/parse
export DATABASE_URI=mongodb://localhost:27017/dev
export PORT=1338
#npm start
nohup node main.js > ./system.log 2>&1 &
