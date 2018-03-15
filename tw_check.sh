#!/bin/sh

while true
do

isAlive=$(ps -ef | grep "twitter_bot" | grep -v grep | wc -l)

if [ "$isAlive" = 1 ]; then
  echo "alive"
else
  echo "dead"
  ruby twitter_bot.rb 
fi

sleep 4
done
