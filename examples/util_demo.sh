#!/bin/sh

if ! command -v util; then
  echo "util not installed. Install it to run this demo."
fi

# Creates a folder under the scripts folder.
# This will be the command.
mkdir -p ~/.config/util/scripts/test

# Creates a simple script which only displays.
# a simple message. The script name will be the subcommand.
cat << EOF > ~/.config/util/scripts/test/example.sh
#!/bin/sh
# help: this is a test command. It only prints a "it works" message

# Completions
# -a[Sample a option]

echo "it works"
EOF

# Make it executable
chmod u+x ~/.config/util/scripts/test/example.sh

# Autocompletions should appear when typing util commands.
# Like `util tes<TAB>` or `util test <TAB>`
# An `util test example <TAB>` should list the flags
# available for the script.

# Run it. It should run the script we just created.
util test example

# There you go. You can arrange your scripts in any folder
# hierarchy you prefer. util will handle possible colisions.
