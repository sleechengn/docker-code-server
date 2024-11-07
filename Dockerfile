FROM ubuntu:jammy
RUN mkdir /opt/cs
WORKDIR /opt/cs
RUN apt update && apt remove -y python* && apt autoremove && apt autoclean && apt autopurge && apt install -y wget git

#install code-server online
RUN wget https://github.com/coder/code-server/releases/download/v4.93.1/code-server_4.93.1_amd64.deb
RUN dpkg -i ./code-server_4.93.1_amd64.deb

#install openjdk21
RUN wget https://download.java.net/openjdk/jdk21/ri/openjdk-21+35_linux-x64_bin.tar.gz
RUN tar -zxvf ./openjdk-21+35_linux-x64_bin.tar.gz
ENV JAVA_HOME=/opt/cs/jdk-21
RUN ln -s /opt/cs/jdk-21/bin/java /usr/bin/java
RUN ln -s /opt/cs/jdk-21/bin/javac /usr/bin/javac

#install python 3.11
RUN apt install -y python3.11 python3-dev python3-pip

RUN /usr/bin/code-server --install-extension vscjava.vscode-java-pack
RUN /usr/bin/code-server --install-extension gabrielbb.vscode-lombok
RUN /usr/bin/code-server --install-extension alphabotsec.vscode-eclipse-keybindings
RUN /usr/bin/code-server --install-extension arzg.intellij-theme
RUN /usr/bin/code-server --install-extension ms-python.python
RUN /usr/bin/code-server --install-extension tht13.python

#COPY ./docker-entrypoint.sh /
#RUN chmod +x /docker-entrypoint.sh

CMD ["--bind-addr", "0.0.0.0:8080", "--auth", "none"]
ENTRYPOINT ["/docker-entrypoint.sh"]

RUN apt install -y nginx ttyd
RUN apt install -y curl
RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
RUN mkdir /opt/filebrowser

RUN rm -rf /etc/nginx/sites-enabled/default
ADD ./NGINX /etc/nginx/sites-enabled/
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

VOLUME /usr/local/lib/python3.11/dist-packages
VOLUME /root
