FROM ubuntu:jammy

#APT-PLACE-HOLDER
RUN set -e \
	&& apt update \
	&& apt remove -y python* \
	&& apt autoremove \
	&& apt autoclean \
	&& apt autopurge \
	&& apt install -y wget git aria2 nginx ttyd curl nano psmisc net-tools gcc make g++ tmux cmake \
	&& apt autoremove \
        && apt autoclean \
        && apt autopurge

#install code-server online
RUN set -e \
	&& mkdir -p /opt/code-server \
	&& cd /opt/code-server \
	&& DOWNLOAD=$(curl -s https://api.github.com/repos/coder/code-server/releases/latest | grep browser_download_url |grep linux|grep amd64| grep -v rocm| cut -d'"' -f4) \
	&& aria2c -x 10 -j 10 -k 1m "$DOWNLOAD" -o "code-server.tar.gz" \
	&& tar -zxvf code-server.tar.gz \
	&& rm -rf code-server.tar.gz \
	&& PATH_PART=$(ls -A /opt/code-server) \
	&& ln -s /opt/code-server/$PATH_PART/bin/code-server /usr/bin/code-server

#install graalvm
RUN set -e \
	&& mkdir -p /opt/graalvm \
	&& cd /opt/graalvm \
	&& aria2c -x 10 -j 10 -k 1m https://download.oracle.com/graalvm/21/latest/graalvm-jdk-21_linux-x64_bin.tar.gz \
	&& tar -zxvf ./graalvm-jdk-21_linux-x64_bin.tar.gz \
	&& rm -rf ./graalvm-jdk-21_linux-x64_bin.tar.gz \
	&& PATH_FRAG=$(ls -A /opt/graalvm) \
	&& ln -s /opt/graalvm/$PATH_FRAG/bin/java /usr/bin/java \
	&& ln -s /opt/graalvm/$PATH_FRAG/bin/javac /usr/bin/javac \
	&& ln -s /opt/graalvm/$PATH_FRAG/bin/native-image /usr/bin/native-image \
	&& java -version
ENV JAVA_HOME=/opt/graalvm/$PATH_FRAG
ENV GRAALVM_HOME=/opt/graalvm/$PATH_FRAG

# mnv
RUN set -e \
        && cd /opt \
        && aria2c --max-connection-per-server=10 --min-split-size=1M --max-concurrent-downloads=10 https://dlcdn.apache.org/maven/maven-3/3.9.11/binaries/apache-maven-3.9.11-bin.tar.gz \
        && tar -zxvf apache-maven-3.9.11-bin.tar.gz \
        && rm -rf apache-maven-3.9.11-bin.tar.gz \
        && ln -s /opt/apache-maven-3.9.11/bin/mvn /usr/bin/mvn

# uv
RUN set -e \
        && mkdir /opt/uv \
        && cd /opt/uv \
        && DOWNLOAD=$(curl -s https://api.github.com/repos/astral-sh/uv/releases/latest | grep browser_download_url |grep linux|grep x86_64| grep -v rocm| cut -d'"' -f4) \
        && aria2c -x 10 -j 10 -k 1M $DOWNLOAD -o uv.tar.gz \
        && tar -zxvf uv.tar.gz \
        && rm -rf uv.tar.gz \
	&& PATH_FRAG=$(ls /opt/uv) \
        && ln -s /opt/uv/$PATH_FRAG/uv /usr/bin/uv \
        && ln -s /opt/uv/$PATH_FRAG/uvx /usr/bin/uvx 

# code-sever extension
# java extension
RUN /usr/bin/code-server --install-extension vscjava.vscode-java-pack
RUN /usr/bin/code-server --install-extension kylinideteam.kylin-cpp-pack
RUN /usr/bin/code-server --install-extension alphabotsec.vscode-eclipse-keybindings 
RUN /usr/bin/code-server --install-extension arzg.intellij-theme
# python extension
RUN /usr/bin/code-server --install-extension ms-python.python
# React Web TS
RUN /usr/bin/code-server --install-extension tomi.xasnippets
RUN /usr/bin/code-server --install-extension franneck94.vscode-typescript-extension-pack
RUN /usr/bin/code-server --install-extension dsznajder.es7-react-js-snippets
# C C++
RUN /usr/bin/code-server --install-extension franneck94.vscode-c-cpp-dev-extension-pack

# filebrowser
run mkdir /opt/filebrowser \
        && cd /opt/filebrowser\
        && DOWNLOAD=$(curl -s https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep browser_download_url |grep linux|grep amd64| grep -v rocm| cut -d'"' -f4) \
        && aria2c -x 10 -j 10 -k 1M $DOWNLOAD -o linux-amd64-filebrowser.tar.gz \
        && tar -zxvf linux-amd64-filebrowser.tar.gz \
        && rm -rf linux-amd64-filebrowser.tar.gz \
        && ln -s /opt/filebrowser/filebrowser /usr/bin/filebrowser

RUN rm -rf /etc/nginx/sites-enabled/default
ADD ./NGINX /etc/nginx/sites-enabled/
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

#install chinese support
RUN set -e \
	&& apt install -y language-pack-zh-hans \
	&& locale-gen zh_CN.UTF-8 \
	&& sed -i '1a\export LC_ALL=zh_CN.UTF-8' /docker-entrypoint.sh

#install scala
RUN set -e \
        && mkdir -p /opt/scala \
        && cd /opt/scala \
        && aria2c --max-connection-per-server=10 --min-split-size=1M --max-concurrent-downloads=10 https://github.com/scala/scala3/releases/download/3.3.5/scala3-3.3.5.tar.gz \
        && tar -zxvf ./scala3-3.3.5.tar.gz \
        && rm -rf ./scala3-3.3.5.tar.gz \
	&& PATH_FRAG=$(ls -A /opt/scala) \
        && ln -s /opt/scala/$PATH_FRAG/bin/scala /usr/bin/scala \
        && ln -s /opt/scala/$PATH_FRAG/bin/scalac /usr/bin/scalac
ENV SCALA_HOME=/opt/scala/$PATH_FRAG

# nodejs
RUN set -e \
	&& mkdir /opt/nodejs \
	&& cd /opt/nodejs && apt install -y xz-utils \
	&& wget https://nodejs.org/dist/v24.7.0/node-v24.7.0-linux-x64.tar.xz \
	&& xz -d node-v24.7.0-linux-x64.tar.xz \
	&& tar -xvf node-v24.7.0-linux-x64.tar \
	&& ln -s /opt/nodejs/node-v24.7.0-linux-x64/bin/node /usr/bin/node \
	&& ln -s /opt/nodejs/node-v24.7.0-linux-x64/bin/npm /usr/bin/npm \
	&& ln -s /opt/nodejs/node-v24.7.0-linux-x64/bin/npx /usr/bin/npx \
	&& rm -rf node-v24.7.0-linux-x64.tar && apt clean

CMD ["--bind-addr", "127.0.0.1:8080", "--auth", "none"]
ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME /root
VOLUME /opt
VOLUME /workspace
