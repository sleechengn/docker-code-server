#!/usr/bin/env bash

set -ex

docker build . -f Dockerfile -t sleechengn/code-server:latest
