#!/bin/sh

curl -L https://github.com/vncsmyrnk/shell-utils/archive/refs/heads/main.zip -o /tmp/shell-utils.zip
unzip /tmp/shell-utils.zip -d /tmp
\. /tmp/shell-utils-main/config/setup
sudo install /tmp/shell-utils-main/bin/util $SU_BIN_PATH
install /tmp/shell-utils-main/config/setup $SU_PATH
mkdir -p $SU_SCRIPTS_PATH && {
  cp /tmp/shell-utils-main/defaults/* $SU_SCRIPTS_PATH
}
