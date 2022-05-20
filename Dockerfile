FROM alpine:3.15
MAINTAINER "EEA: IDM2 A-Team" <eea-edw-a-team-alerts@googlegroups.com>

RUN apk add --no-cache --virtual .run-deps rsync openssh tzdata curl ca-certificates && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /data

COPY docker-entrypoint.sh /

VOLUME [ "/data" ]
EXPOSE 22

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["sh"]
