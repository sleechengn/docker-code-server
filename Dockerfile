FROM ubuntu:jammy

RUN mkdir /opt/cs
WORKDIR /opt/cs
#APT-PLACE-HOLDER
RUN set -e \
	&& apt update \
	&& apt remove -y python* \
	&& apt autoremove \
	&& apt autoclean \
	&& apt autopurge \
	&& apt install -y wget git aria2

#install code-server online
RUN set -e \
	&& aria2c --max-connection-per-server=10 --min-split-size=1M --max-concurrent-downloads=10 "https://github.com/coder/code-server/releases/download/v4.93.1/code-server_4.93.1_amd64.deb" -o "code-server_4.93.1_amd64.deb" \
	&& dpkg -i ./code-server_4.93.1_amd64.deb \
	&& rm -rf ./code-server_4.93.1_amd64.deb

#install graalvm
RUN set -e \
	&& mkdir -p /opt/graalvm \
	&& cd /opt/graalvm \
	&& aria2c --max-connection-per-server=10 --min-split-size=1M --max-concurrent-downloads=10 https://download.oracle.com/graalvm/21/latest/graalvm-jdk-21_linux-x64_bin.tar.gz \
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
        && apt install -y curl \
        && mkdir /opt/uv \
        && cd /opt/uv \
        && DOWNLOAD=$(curl -s https://api.github.com/repos/astral-sh/uv/releases/latest | grep browser_download_url |grep linux|grep x86_64| grep -v rocm| cut -d'"' -f4) \
        && aria2c -x 10 -j 10 -k 1M $DOWNLOAD -o uv.tar.gz \
        && tar -zxvf uv.tar.gz \
        && rm -rf uv.tar.gz \
	&& PATH_FRAG=$(ls /opt/uv) \
        && ln -s /opt/uv/$PATH_FRAG/uv /usr/bin/uv \
        && ln -s /opt/uv/$PATH_FRAG/uvx /usr/bin/uvx \
        && uv venv /opt/venv --python 3.12

# code-sever
RUN set -e \
	&& /usr/bin/code-server --install-extension vscjava.vscode-java-pack \
	&& /usr/bin/code-server --install-extension kylinideteam.kylin-cpp-pack \
	&& /usr/bin/code-server --install-extension alphabotsec.vscode-eclipse-keybindings \
	&& /usr/bin/code-server --install-extension arzg.intellij-theme \
	&& /usr/bin/code-server --install-extension ms-python.python \
	&& /usr/bin/code-server --install-extension ms-vscode.vscode-typescript-next

RUN set -e \
	&& apt install -y nginx ttyd \
	&& apt install -y curl \
	&& curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash \
	&& mkdir /opt/filebrowser \
	&& apt autoremove

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

CMD ["--bind-addr", "127.0.0.1:8080", "--auth", "none"]
ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME /root
VOLUME /opt
VOLUME /workspace
