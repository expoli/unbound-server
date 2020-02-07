FROM ubuntu:latest

RUN apt-get update\
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

EXPOSE 853/tcp 853/udp
# This command runs your application, comment out this line to compile only
ENTRYPOINT ["/entrypoint.sh"]

CMD [ "netstate", "-ntlp" ]
