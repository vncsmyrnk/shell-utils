#!/bin/sh

# [help]
# Cycles through the running docker containers and stop them

docker ps |
  awk '{ print $1 }' |
  xargs docker stop
