#!/bin/sh

# Lib for defining the rules for adding custom scripts
# to be found when running util

stow_to_scripts_path() {
  [ -d $SU_SCRIPTS_PATH ] || return 1
  folder_path="$SU_SCRIPTS_PATH/$1"
  mkdir -p $folder_path
  stow -t $folder_path $1 --no-folding
}

unstow_to_scripts_path() {
  [ -d $SU_SCRIPTS_PATH ] || return 1
  folder_path="$SU_SCRIPTS_PATH/$1"
  stow -D -t $folder_path $1 --no-folding
  rm -rf $folder_path
}

stow_to_setup_path() {
  [ -d $SU_RC_SOURCE_PATH ] || return 1
  folder_path="$SU_RC_SOURCE_PATH/$1"
  mkdir -p $folder_path
  stow -t $folder_path $1 --no-folding
}

unstow_to_setup_path() {
  [ -d $SU_RC_SOURCE_PATH ] || return 1
  folder_path="$SU_RC_SOURCE_PATH/$1"
  stow -D -t $folder_path $1 --no-folding
  rm -rf $folder_path
}
