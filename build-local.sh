#!/usr/bin/env bash
mkdir -p /opt/tmp
rm -rf /opt/tmp/code-server-build
cp -ra . /opt/tmp/code-server-build
cd /opt/tmp/code-server-build
rm -rf .git

sed -i 's,FROM debian\:trixie,FROM 192.168.13.73:5000/debian:trixie,g' Dockerfile

sed -i '1i\# syntax=docker/dockerfile:1.3' Dockerfile

sed -i "/^#APT-PLACE-HOLDER.*/i\RUN apt update" Dockerfile
sed -i "/^#APT-PLACE-HOLDER.*/i\RUN apt install -y apt-transport-https ca-certificates" Dockerfile
#sed -i '/^#APT-PLACE-HOLDER.*/i\RUN sed -i "s,http://deb.debian.org/,https://mirrors.tuna.tsinghua.edu.cn/,g" /etc/apt/sources.list' Dockerfile
sed -i '/^#APT-PLACE-HOLDER.*/i\RUN sed -i "s,http://deb.debian.org/,https://mirrors.tuna.tsinghua.edu.cn/,g" /etc/apt/sources.list.d/debian.sources' Dockerfile
sed -i '/^#APT-PLACE-HOLDER.*/i\RUN apt update' Dockerfile

# local source optional
echo "检测本地apt"
if [ -e "/mnt/rfs/soft/scripts/apt-download/debs/debian/13/a-local-src.list" ]; then
    mkdir -p apt-sources
    mount -o bind /mnt/rfs/soft/scripts/apt-download/debs/debian/13 apt-sources
    echo "替换RUN指令"
    sed -i "s#^RUN echo apt-install #RUN --mount=type=bind,target=/mnt/rfs/soft/scripts/apt-download/debs/debian/13,ro,source=apt-sources echo apt-install #g" Dockerfile
    sed -i '/^#APT-PLACE-HOLDER.*/i\RUN --mount=type=bind,target=/mnt/rfs/soft/scripts/apt-download/debs/debian/13,ro,source=apt-sources cp /mnt/rfs/soft/scripts/apt-download/debs/debian/13/a-local-src.list /etc/apt/sources.list.d' Dockerfile
    sed -i '/^#APT-PLACE-HOLDER.*/i\RUN --mount=type=bind,target=/mnt/rfs/soft/scripts/apt-download/debs/debian/13,ro,source=apt-sources apt update' Dockerfile
fi

echo "检测本地code-server源"
if [ -e "/mnt/rfs/soft/sdn/vscode/code-server/4.23.1/code-server-4.23.1-linux-amd64.tar.gz" ]; then
    mkdir -p code-server-sources
    if [ ! -e "code-server-sources/code-server-4.23.1-linux-amd64.tar.gz" ]; then
        cp /mnt/rfs/soft/sdn/vscode/code-server/4.23.1/code-server-4.23.1-linux-amd64.tar.gz code-server-sources
    fi
    sed -i "s#^RUN echo code-server-install #RUN --mount=type=bind,target=/opt/tmp/code-server,ro,source=code-server-sources echo code-server-install #g" Dockerfile
    sed -i "/.*echo fetch-code-server-url.*/d" Dockerfile
    sed -i "/.*echo fetch-code-server-tar.*/d" Dockerfile
    sed -i "s#echo exist code-server-tar#cp /opt/tmp/code-server/code-server-4.23.1-linux-amd64.tar.gz code-server.tar.gz#g" Dockerfile
fi

echo "检测本地graalvm"
if [ -e "/mnt/rfs/soft/sdn/java/graalvm/graalvm-jdk-21_linux-x64_bin.tar.gz" ]; then
    mkdir -p graalvm-sources
    if [ ! -e "graalvm-sources/graalvm-jdk-21_linux-x64_bin.tar.gz" ]; then
        cp /mnt/rfs/soft/sdn/java/graalvm/graalvm-jdk-21_linux-x64_bin.tar.gz graalvm-sources
    fi
    sed -i "s#^RUN echo install-graalvm #RUN --mount=type=bind,target=/opt/tmp/graalvm,ro,source=graalvm-sources echo graalvm-install #g" Dockerfile
    sed -i "/.*echo fetch-graalvm-tar.*/d" Dockerfile
    sed -i "s#echo exist graalvm#cp /opt/tmp/graalvm/graalvm-jdk-21_linux-x64_bin.tar.gz graalvm-jdk-21_linux-x64_bin.tar.gz#g" Dockerfile
fi

docker --debug build . -f Dockerfile -t 192.168.13.73:5000/sleechengn/code-server:latest
docker push 192.168.13.73:5000/sleechengn/code-server:latest
umount apt-sources
