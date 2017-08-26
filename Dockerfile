FROM alpine
MAINTAINER Alex Egorov <alex202@egorov.net>

RUN apk add --update mysql-client openssl && rm -rf /var/cache/apk/*

COPY ./mysql_backup.sh /usr/local/bin/mysql_backup.sh

VOLUME /backup

ENTRYPOINT ["/usr/local/bin/mysql_backup.sh"]
