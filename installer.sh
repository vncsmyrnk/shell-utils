#!/bin/sh

curl -L https://github.com/vncsmyrnk/shell-utils/raw/refs/heads/main/bin/util.sh -o /tmp/util
sudo install /tmp/util /usr/local/bin
