# vim: set ft=sh:

export SU_PATH=$HOME/.config/util
export SU_BIN_PATH=/usr/local/bin
export SU_SCRIPTS_PATH=$SU_PATH/scripts
export SU_SCRIPTS_ON_UPDATE_PATH=$SU_PATH/scripts/on-update
export SU_RC_SOURCE_PATH=$SU_PATH/setup
export SU_RC_SOURCE_PRIORITY_ORDER=${SU_RC_SOURCE_PRIORITY_ORDER:-}
export SU_COMPLETIONS_PATH=$SU_PATH/completions
export SU_BKP_PATHS="$HOME/.zshrc.private $HOME/.env $HOME/Documents $HOME/update.sh $HOME/.password-store"
