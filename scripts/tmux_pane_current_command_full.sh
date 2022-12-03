#!/bin/bash

if [[ $# -lt 1 ]]
then
	echo "Usage: $0 [pane identifier (session:0.left or %2)]"
	echo "Returns full command executing from that pane, similar to:"
	echo "tmux display -pt [pane identifier] '#{pane_current_command}'"
	echo "But this script will return the full command."
	echo
	echo "If no pane is found, it will exit with code 2."
	echo "If no command is running, it will print an empty line."
	exit 1
fi

if ! command -v tmux &> /dev/null
then
	>&2 echo "tmux command not found."
    exit 2
fi

tmux list-panes -t "$1" &> /dev/null
if [[ $? -ne 0 ]]
then
	>&2 echo "No pane detected"
	exit 3
fi

# `tmux display` doesn't match strictly and it will give you any pane if not found.
pane_pid=$(tmux display -pt "$1" '#{pane_pid}')
if [[ -z $pane_pid ]]
then
	>&2 echo "No pane detected"
	exit 3
fi

command_pid=$(ps -el | awk "\$5==$pane_pid" | awk '{print $4}')
if [[ ! -z $command_pid ]]	# sometimes no command is running
then
	full_command=$(ps --no-headers -u -p $command_pid | awk '{for(i=11;i<=NF;++i)printf $i" "}' )
	echo "$full_command"
else
	echo ''
fi

