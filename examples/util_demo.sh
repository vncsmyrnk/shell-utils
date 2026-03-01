#!/bin/sh

if ! command -v util; then
  echo "util not installed. Install it to run this demo."
fi

# Creates a simple script which only displays.
# a simple message. The script name will be the subcommand.
cat <<EOF >~/myscripts/example.sh
#!/bin/sh
# [help]
# This is a test command. It only prints a "it works" message

echo "it works"
EOF

# Make it executable
chmod u+x ~/myscripts/example.sh

# Make it acessible to the util command
util config add ~/myscripts/example.sh

# Autocompletions can be defined at
# ~/.config/util/scripts/example.completions.[shell] (i.e
# ~/.config/util/scripts/example.completions.zsh).

# Run it. It should run the script we just created.
util example

# There you go. You can arrange your scripts in any folder
# hierarchy you prefer. util will handle possible colisions.
