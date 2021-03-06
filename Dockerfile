FROM alpine:latest

RUN apk --no-cache add \
    unbound \
    openssl\
    wget\
    bash\
    bind-tools\
    && touch /var/log/unbound.log\
    && chown unbound:unbound /var/log/unbound.log

COPY ./unbound.conf /etc/unbound/unbound.conf
COPY ./entrypoint.sh /entrypoint.sh

# These commands copy your files into the specified directory in the image
# and set that as the working location
WORKDIR /

VOLUME [ "/etc/unbound/ssl/" ]

EXPOSE 853/tcp 853/udp
# This command runs your application, comment out this line to compile only
CMD ["/entrypoint.sh"]
