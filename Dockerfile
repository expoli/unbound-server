FROM ubuntu:latest

RUN sed -i "s/archive.ubuntu.com/mirrors.aliyun.com/g" /etc/apt/sources.list\
    && apt-get update\
    && apt-get install -y \
    libevent-dev\
    libsodium-dev\
    libsystemd-dev\
    libsystemd-dev\
    libssl-dev\
    libexpat-dev\
    gcc\
    make\
    wget\
    libcap2-bin\
    dnsutils\
    net-tools\
    && apt-get clean

COPY ./release-1.9.6.tar.gz /opt
RUN tar zxf /opt/release-1.9.6.tar.gz \
    && cd unbound-release-1.9.6\
    &&  ./configure --prefix=/usr   --sysconfdir=/etc  --disable-static   --with-pidfile=/run/unbound.pid  --enable-debug    --enable-cachedb     --enable-dnscrypt --with-libevent\
    && make\
    && make install\
    && mv -v /usr/sbin/unbound-host /usr/bin/\
    && cd /\
    && rm unbound-release-1.9.6 -rf

COPY ./unbound.conf /etc/unbound/unbound.conf
COPY ./entrypoint.sh /entrypoint.sh

# These commands copy your files into the specified directory in the image
# and set that as the working location
WORKDIR /

VOLUME [ "/etc/unbound/ssl/" ]

EXPOSE 853
# This command runs your application, comment out this line to compile only
CMD ["/entrypoint.sh"]

LABEL Name=unbound Version=1.0.0