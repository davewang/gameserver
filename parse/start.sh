#!/usr/bin/env bash
export MASTER_KEY=abcd12345678
export APP_ID=Silk
export APP_NAME=Silk
export SERVER_URL=https://iapploft.net:1337/parse
export DATABASE_URI=mongodb://localhost:27017/dev
export PORT=1337
#npm start
nohup node index.js > ./system.log 2>&1 &
