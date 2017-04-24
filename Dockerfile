FROM alpine:3.5
MAINTAINER "EEA: IDM2 A-Team" <eea-edw-a-team-alerts@googlegroups.com>

RUN apk add --no-cache --virtual .run-deps rsync openssh tzdata
COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["sh"]
