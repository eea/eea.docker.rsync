FROM alpine:3.3
MAINTAINER "EEA: IDM2 A-Team" <eea-edw-a-team-alerts@googlegroups.com>

RUN apk add --no-cache --virtual .run-deps rsync openssh
COPY docker-entrypoint.sh /

VOLUME /root
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["sh"]
