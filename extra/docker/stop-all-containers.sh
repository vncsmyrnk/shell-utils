#!/bin/sh

docker ps \
  | awk '{ print $1 }' \
  | xargs docker stop
