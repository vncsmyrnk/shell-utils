#!/bin/sh

# help: lists backups uploaded to the current set rclone remote

rclone ls $SU_SCRIPT_BACKUP_RCLONE_REMOTE:$SU_SCRIPT_BACKUP_RCLONE_FOLDER
