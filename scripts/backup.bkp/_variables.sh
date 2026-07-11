# vim: set ft=sh:

_backup_paths=${SHELL_UTILS_BKP_PATHS-"$HOME/.zshrc.private $HOME/.env $HOME/Documents $HOME/update.sh $HOME/.password-store $HOME/.config/shell-utils"}
_backup_zip_dir=${SHELL_UTILS_BACKUP_ZIP_DIR:-/tmp}
_backup_encrypted_dir=${SHELL_UTILS_BACKUP_ENCRYPTED_DIR:-$_backup_zip_dir}
_backup_encrypt_password=${SHELL_UTILS_BACKUP_ENCRYPT_PASSWORD:-""}
_backup_rclone_remote=${SHELL_UTILS_BACKUP_RCLONE_REMOTE:-"gdrive"}
_backup_rclone_folder=${SHELL_UTILS_BACKUP_RCLONE_FOLDER:-"bkp"}

target_basename="backup_$(date +"%Y%m%d%H%M%S").zip"
_backup_zip_file_path="$_backup_zip_dir/$target_basename"
_backup_encrypted_file_path="$_backup_encrypted_dir/$target_basename.enc"

_backup_remote_unwrap_dest=${SHELL_UTILS_REMOTE_UNWRAP_DEST:-/tmp}
