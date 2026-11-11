#!/usr/bin/env bash

set -ex

docker run --rm --name code-server -p 8033:80 -v /mnt:/mnt sleechengn/code-server:latest
