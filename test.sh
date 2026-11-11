#!/usr/bin/bash
#docker ps -a|grep code-server|grep -v grep|awk '{print $1}'|xargs -i docker stop {}
docker run --rm --name code-server -p 8033:80 -v /mnt:/mnt sleechengn/code-server:latest
