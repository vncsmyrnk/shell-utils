#!/bin/sh

# Downloads shell-utils files and install them on
# the expected directories

PROJECT_NAME=shell-utils
BRANCH=main

curl -L "https://github.com/vncsmyrnk/$PROJECT_NAME/archive/refs/heads/$BRANCH.zip" \
  -o "/tmp/$PROJECT_NAME.zip"
unzip "/tmp/$PROJECT_NAME.zip" -d /tmp
\. "/tmp/$PROJECT_NAME-$BRANCH/config/setup"
sudo install -d "/tmp/$PROJECT_NAME-$BRANCH/bin/util" "$SU_BIN_PATH"
install -d "/tmp/$PROJECT_NAME-$BRANCH/config/setup" "$SU_PATH"
mkdir -p "$SU_SCRIPTS_PATH" && {
  cp "/tmp/$PROJECT_NAME-$BRANCH/defaults/*" "$SU_SCRIPTS_PATH"
}
