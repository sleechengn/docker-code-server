#!/usr/bin/env bash
set -e

mkdir -p /opt/tmp
rm -rf /opt/tmp/code-server-build
cp -ra . /opt/tmp/code-server-build
cd /opt/tmp/code-server-build
rm -rf .git

if [ $(arch) == "x86_64" ]; then
    sed -i 's,FROM debian\:trixie,FROM 192.168.13.73:5000/debian-x86_64:trixie,g' Dockerfile
fi
sed -i '1i\# syntax=docker/dockerfile:1.3' Dockerfile

sed -i "/^#APT-PLACE-HOLDER.*/i\RUN apt update" Dockerfile
sed -i "/^#APT-PLACE-HOLDER.*/i\RUN apt install -y apt-transport-https ca-certificates" Dockerfile
#sed -i '/^#APT-PLACE-HOLDER.*/i\RUN sed -i "s,http://deb.debian.org/,https://mirrors.tuna.tsinghua.edu.cn/,g" /etc/apt/sources.list' Dockerfile
sed -i '/^#APT-PLACE-HOLDER.*/i\RUN sed -i "s,http://deb.debian.org/,https://mirrors.tuna.tsinghua.edu.cn/,g" /etc/apt/sources.list.d/debian.sources' Dockerfile
sed -i '/^#APT-PLACE-HOLDER.*/i\RUN apt update' Dockerfile

# local source optional
echo "detect apt"
if [ "$(arch)" == "x86_64" ] && [ -e "/mnt/ext/soft/scripts/apt-download/debs/debian/13/a-local-src.list" ]; then
    mkdir -p apt-sources
    mount -o bind /mnt/ext/soft/scripts/apt-download/debs/debian/13 apt-sources
    echo "replace RUN instruction"
    sed -i "s#^RUN echo apt-install #RUN --mount=type=bind,target=/mnt/vol2/soft/scripts/apt-download/debs/debian/13,ro,source=apt-sources echo apt-install #g" Dockerfile
    sed -i '/^#APT-PLACE-HOLDER.*/i\RUN --mount=type=bind,target=/mnt/vol2/soft/scripts/apt-download/debs/debian/13,ro,source=apt-sources cp /mnt/vol2/soft/scripts/apt-download/debs/debian/13/a-local-src.list /etc/apt/sources.list.d' Dockerfile
    sed -i '/^#APT-PLACE-HOLDER.*/i\RUN --mount=type=bind,target=/mnt/vol2/soft/scripts/apt-download/debs/debian/13,ro,source=apt-sources apt update' Dockerfile
fi

CODE_SERVER_LOCAL_TAR_GZ="/mnt/vol2/soft/sdn/vscode/code-server/4.23.1/code-server-4.23.1-linux-amd64.tar.gz"
echo "detect code-server source"
if [ "$(arch)" == "x86_64" ] && [ -e "$CODE_SERVER_LOCAL_TAR_GZ" ]; then
    mkdir -p code-server-sources
    if [ ! -e "code-server-sources/code-server.tar.gz" ]; then
        cp $CODE_SERVER_LOCAL_TAR_GZ code-server-sources/code-server.tar.gz
    fi
    sed -i "s#^RUN echo code-server-install #RUN --mount=type=bind,target=/opt/tmp/code-server,ro,source=code-server-sources echo code-server-install #g" Dockerfile
    sed -i "/.*echo fetch-code-server-url.*/d" Dockerfile
    sed -i "/.*echo fetch-code-server-tar.*/d" Dockerfile
    sed -i "s#echo exist code-server-tar#cp /opt/tmp/code-server/code-server.tar.gz code-server.tar.gz#g" Dockerfile
fi

GRAALVM_LOCAL_TAR_GZ="/mnt/vol2/soft/sdn/java/graalvm/graalvm-jdk-21_linux-x64_bin.tar.gz"
echo "detect graalvm"
if [ "$(arch)" == "x86_64" ] && [ -e "$GRAALVM_LOCAL_TAR_GZ" ]; then
    mkdir -p graalvm-sources
    if [ ! -e "graalvm-sources/graalvm-community-jdk-21.0.1_linux_bin.tar.gz" ]; then
        cp $GRAALVM_LOCAL_TAR_GZ graalvm-sources/graalvm-community-jdk-21.0.1_linux_bin.tar.gz
    fi
    sed -i "s#^RUN echo install-graalvm #RUN --mount=type=bind,target=/opt/tmp/graalvm,ro,source=graalvm-sources echo graalvm-install #g" Dockerfile
    sed -i "/.*echo fetch-graalvm-tar.*/d" Dockerfile
    sed -i "s#echo exist graalvm#cp /opt/tmp/graalvm/graalvm-community-jdk-21.0.1_linux_bin.tar.gz graalvm-community-jdk-21.0.1_linux_bin.tar.gz#g" Dockerfile
fi

MAVEN_LOCAL_TAR_GZ="/mnt/vol2/soft/sdn/java/maven/apache-maven-3.9.10-bin.tar.gz"
echo "detect mvn"
if [ "$(arch)" == "x86_64" ] && [ -e "$MAVEN_LOCAL_TAR_GZ" ]; then
    mkdir -p mvn-sources
    if [ ! -e "mvn-sources/apache-maven.tar.gz" ]; then
        cp $MAVEN_LOCAL_TAR_GZ mvn-sources/apache-maven.tar.gz
    fi
    sed -i "s#^RUN echo install-mvn #RUN --mount=type=bind,target=/opt/tmp/maven,ro,source=mvn-sources echo install-mvn #g" Dockerfile
    sed -i "/.*echo pull-mvn-bin.*/d" Dockerfile
    sed -i "s#echo unpack-mvn-bin#cp /opt/tmp/maven/apache-maven.tar.gz apache-maven.tar.gz#g" Dockerfile
fi

UV_LOCAL_TGZ="/mnt/vol2/soft/sdn/python/venv/uv/0.6.6/uv-x86_64-unknown-linux-gnu.tar.gz"
echo "detect uv"
#/mnt/vol2/soft/sdn/python/venv/uv/0.6.6/uv-x86_64-unknown-linux-gnu.tar.gz
if [ "$(arch)" == "x86_64" ] && [ -e "$UV_LOCAL_TGZ" ]; then
    mkdir -p uv-sources
    if [ ! -e "uv-sources/uv.tar.gz" ]; then
        cp $UV_LOCAL_TGZ uv-sources/uv.tar.gz
    fi
    sed -i "s#^RUN echo install-uv #RUN --mount=type=bind,target=/opt/tmp/uv,ro,source=uv-sources echo install-uv #g" Dockerfile
    sed -i "/.*echo fetch-uv-url.*/d" Dockerfile
    sed -i "/.*echo fetch-uv-bin.*/d" Dockerfile
    sed -i "s#echo unpack-uv-bin#cp /opt/tmp/uv/uv.tar.gz uv.tar.gz#g" Dockerfile
fi

if [ "$(arch)" == "x86_64" ]; then
	CODE_SERVER_URL=$(curl -s https://api.github.com/repos/coder/code-server/releases/latest | grep browser_download_url |grep linux|grep amd64| grep -v rocm| cut -d'"' -f4)
    UV_DL_URL=$(curl -s https://api.github.com/repos/astral-sh/uv/releases/latest | grep browser_download_url |grep linux|grep x86_64| grep -v rocm|grep -v sha256|grep -v musl| cut -d'"' -f4)
	sed -i "s#^ARG GRAALVM_DL=.*#ARG GRAALVM_DL=https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-21.0.2/graalvm-community-jdk-21.0.2_linux-x64_bin.tar.gz#g" Dockerfile
	sed -i "s#^ARG CODE_SERVER_DL=.*#ARG CODE_SERVER_DL=${CODE_SERVER_URL:-https://github.com/coder/code-server/releases/download/v4.124.2/code-server-4.124.2-linux-amd64.tar.gz}#g" Dockerfile
    sed -i "s#^ARG UV_DL_URL=.*#ARG UV_DL_URL=${UV_DL_URL}#g" Dockerfile
    FBS_DL_URL=$(curl -s https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep browser_download_url |grep linux|grep amd64| grep -v rocm| cut -d'"' -f4)
    sed -i "s#^ARG FBS_DL_URL=.*#ARG FBS_DL_URL=${FBS_DL_URL:-https://releases.astral.sh/github/uv/releases/download/0.11.26/uv-x86_64-unknown-linux-gnu.tar.gz}#g" Dockerfile
    NODE_DL_URL=https://nodejs.org/dist/v22.9.0/node-v22.9.0-linux-x64.tar.xz
    sed -i "s#^ARG NODE_DL_URL=.*#ARG NODE_DL_URL=${NODE_DL_URL}#g" Dockerfile
    TRSZ_DL_URL=$(curl -s https://api.github.com/repos/trzsz/trzsz-go/releases/latest | grep browser_download_url |grep linux_x86_64|grep tar| cut -d'"' -f4)
    sed -i "s#^ARG TRSZ_DL_URL=.*#ARG TRSZ_DL_URL=${TRSZ_DL_URL}#g" Dockerfile
    TTYD_DL_URL=$(curl -s https://api.github.com/repos/tsl0922/ttyd/releases/latest | grep browser_download_url |grep ttyd.x86_64| cut -d'"' -f4)
    sed -i "s#^ARG TTYD_DL_URL=.*#ARG TTYD_DL_URL=${TTYD_DL_URL}#g" Dockerfile
fi
if [ "$(arch)" == "aarch64" ] || [ "$(arch)" == "arm64" ]; then
	CODE_SERVER_URL=$(curl -s https://api.github.com/repos/coder/code-server/releases/latest | grep browser_download_url |grep linux|grep arm64| grep -v rocm| cut -d'"' -f4)
	if [ ! "$CODE_SERVER_URL" ]; then
        echo "pull code server error"
        exit 1
    else
        echo "CODE_SERVER_URL=$CODE_SERVER_URL"
    fi
    UV_DL_URL=$(curl -s https://api.github.com/repos/astral-sh/uv/releases/latest | grep browser_download_url |grep linux|grep aarch64| grep -v rocm|grep -v sha256|grep -v musl|cut -d'"' -f4)
    if [ ! "$UV_DL_URL" ]; then
        echo "pull UV_DL_URL error"
        exit 1
    else
        echo "UV_DL_URL=$UV_DL_URL"
    fi
    sed -i "s#^ARG GRAALVM_DL=.*#ARG GRAALVM_DL=https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-21.0.2/graalvm-community-jdk-21.0.2_linux-aarch64_bin.tar.gz#g" Dockerfile
    sed -i "s#^ARG CODE_SERVER_DL=.*#ARG CODE_SERVER_DL=${CODE_SERVER_URL}#g" Dockerfile
    sed -i "s#^ARG UV_DL_URL=.*#ARG UV_DL_URL=${UV_DL_URL:-https://releases.astral.sh/github/uv/releases/download/0.11.26/uv-aarch64-unknown-linux-gnu.tar.gz}#g" Dockerfile
    FBS_DL_URL=$(curl -s https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep browser_download_url |grep linux|grep arm64| grep -v rocm| cut -d'"' -f4)
    if [ ! "$FBS_DL_URL" ]; then
        echo "pull FBS_DL_URL error"
        exit 1
    else
        echo "FBS_DL_URL=$FBS_DL_URL"
    fi
    sed -i "s#^ARG FBS_DL_URL=.*#ARG FBS_DL_URL=${FBS_DL_URL:-https://github.com/filebrowser/filebrowser/releases/download/v2.63.17/linux-arm64-filebrowser.tar.gz}#g" Dockerfile
    NODE_DL_URL=https://nodejs.org/dist/v22.9.0/node-v22.9.0-linux-arm64.tar.xz
    if [ ! "$NODE_DL_URL" ]; then
        echo "pull NODE_DL_URL error"
        exit 1
    else
        echo "NODE_DL_URL=$NODE_DL_URL"
    fi
    sed -i "s#^ARG NODE_DL_URL=.*#ARG NODE_DL_URL=${NODE_DL_URL}#g" Dockerfile
    TRSZ_DL_URL=$(curl -s https://api.github.com/repos/trzsz/trzsz-go/releases/latest | grep browser_download_url |grep linux_aarch64|grep tar| cut -d'"' -f4)
    if [ ! "$TRSZ_DL_URL" ]; then
        echo "pull TRSZ_DL_URL error"
        exit 1
    else
        echo "TRSZ_DL_URL=$TRSZ_DL_URL"
    fi
    sed -i "s#^ARG TRSZ_DL_URL=.*#ARG TRSZ_DL_URL=${TRSZ_DL_URL}#g" Dockerfile
    TTYD_DL_URL=$(curl -s https://api.github.com/repos/tsl0922/ttyd/releases/latest | grep browser_download_url |grep ttyd.aarch64| cut -d'"' -f4)
    if [ ! "$TTYD_DL_URL" ]; then
        echo "pull TTYD_DL_URL error"
        exit 1
    else
        echo "TTYD_DL_URL=$TTYD_DL_URL"
    fi
    sed -i "s#^ARG TTYD_DL_URL=.*#ARG TTYD_DL_URL=${TTYD_DL_URL}#g" Dockerfile
fi
docker --debug build . -f Dockerfile -t 192.168.13.73:5000/sleechengn/code-server-$(arch):latest
docker push 192.168.13.73:5000/sleechengn/code-server-$(arch):latest
umount apt-sources
