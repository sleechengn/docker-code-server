#!/usr/bin/bash

nohup nginx > /dev/null &
nohup filebrowser -d /opt/filebrowser/filebrowser.db -a 127.0.0.1 -p 8081 -b /filebrowser -r / --noauth > /dev/null &
nohup ttyd --port 8082 --base-path /ttyd --writable -t enableZmodem=true /usr/bin/bash > /dev/null &

cat > ~/.tmux.conf <<EOF
set -g mouse on
unbind -n MouseDown3Pane
EOF
tmux source ~/.tmux.conf

/usr/bin/code-server $*
