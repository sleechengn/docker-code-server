#!/usr/bin/bash
mkdir -p /opt/tmp
rm -rf /opt/tmp/code-server
cp -ra ../code-server /opt/tmp
cd /opt/tmp/code-server
rm -rf .git

sed -i 's,FROM ubuntu\:jammy,FROM 192.168.13.73:5000/ubuntu:jammy,g' Dockerfile

#sed -i '1a\RUN echo "deb http://mirrors.163.com/ubuntu/ jammy-backports main restricted universe multiverse" >> /etc/apt/sources.list' Dockerfile
#sed -i '1a\RUN echo "deb http://mirrors.163.com/ubuntu/ jammy-proposed main restricted universe multiverse" >> /etc/apt/sources.list' Dockerfile
#sed -i '1a\RUN echo "deb http://mirrors.163.com/ubuntu/ jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list' Dockerfile
#sed -i '1a\RUN echo "deb http://mirrors.163.com/ubuntu/ jammy-security main restricted universe multiverse" >> /etc/apt/sources.list' Dockerfile
#sed -i '1a\RUN echo "deb http://mirrors.163.com/ubuntu/ jammy main restricted universe multiverse" >> /etc/apt/sources.list' Dockerfile
#sed -i '1a\RUN mv /etc/apt/sources.list /etc/apt/sources.list.back' Dockerfile

docker --debug build . -f Dockerfile -t 192.168.13.73:5000/sleechengn/code-server:latest
docker push 192.168.13.73:5000/sleechengn/code-server:latest
