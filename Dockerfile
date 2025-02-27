FROM ubuntu:jammy

RUN mkdir /opt/cs
WORKDIR /opt/cs


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

#install openjdk21
#RUN set -e \
#	&& aria2c --max-connection-per-server=10 --min-split-size=1M --max-concurrent-downloads=10 https://download.java.net/openjdk/jdk21/ri/openjdk-21+35_linux-x64_bin.tar.gz \
#	&& tar -zxvf ./openjdk-21+35_linux-x64_bin.tar.gz \
#	&& rm -rf ./openjdk-21+35_linux-x64_bin.tar.gz \
#	&& ln -s /opt/cs/jdk-21/bin/java /usr/bin/java \
#	&& ln -s /opt/cs/jdk-21/bin/javac /usr/bin/javac
#ENV JAVA_HOME=/opt/cs/jdk-21

#install graalvm
RUN set -e \
	&& mkdir -p /opt/graalvm \
	&& cd /opt/graalvm \
	&& aria2c --max-connection-per-server=10 --min-split-size=1M --max-concurrent-downloads=10 https://download.oracle.com/graalvm/21/latest/graalvm-jdk-21_linux-x64_bin.tar.gz \
	&& tar -zxvf ./graalvm-jdk-21_linux-x64_bin.tar.gz \
	&& rm -rf ./graalvm-jdk-21_linux-x64_bin.tar.gz \
	&& ln -s /opt/graalvm/graalvm-jdk-21.0.6+8.1/bin/java /usr/bin/java \
	&& ln -s /opt/graalvm/graalvm-jdk-21.0.6+8.1/bin/javac /usr/bin/javac \
	&& ln -s /opt/graalvm/graalvm-jdk-21.0.6+8.1/bin/native-image /usr/bin/native-image
ENV JAVA_HOME=/opt/graalvm/graalvm-jdk-21.0.6+8.1
ENV GRAALVM_HOME=/opt/graalvm/graalvm-jdk-21.0.6+8.1

RUN set -e \
	&& cd /opt \
	&& aria2c --max-connection-per-server=10 --min-split-size=1M --max-concurrent-downloads=10 https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz \
	&& tar -zxvf apache-maven-3.9.9-bin.tar.gz \
	&& rm -rf apache-maven-3.9.9-bin.tar.gz \
	&& ln -s /opt/apache-maven-3.9.9/bin/mvn /usr/bin/mvn

#install python 3.10
RUN set -e \
	&& apt install -y python3.10 python3-dev python3-pip python3.10-venv \ 
	&& rm -rf /usr/bin/python3 \
	&& rm -rf /usr/bin/python \
	&& ln -s $(which python3.10) /usr/bin/python \
	&& ln -s $(which python3.10) /usr/bin/python3

RUN set -e \
	&& /usr/bin/code-server --install-extension vscjava.vscode-java-pack \
	&& /usr/bin/code-server --install-extension gabrielbb.vscode-lombok \
	&& /usr/bin/code-server --install-extension alphabotsec.vscode-eclipse-keybindings \
	&& /usr/bin/code-server --install-extension arzg.intellij-theme \
	&& /usr/bin/code-server --install-extension ms-python.python \
	&& /usr/bin/code-server --install-extension tht13.python

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

CMD ["--bind-addr", "127.0.0.1:8080", "--auth", "none"]
ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME /usr/local/lib/python3.10/dist-packages
VOLUME /root
VOLUME /opt
VOLUME /workspace
