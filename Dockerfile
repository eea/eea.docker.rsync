FROM alpine:3.20.2
LABEL maintainer="EEA: IDM2 A-Team <eea-edw-a-team-alerts@googlegroups.com>"

#remove after upgrade on alpine >3.20
#fix for CVE-2024-39894
RUN apk add --no-cache --virtual openssh=9.8_p1-r4 --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main  \
   && rm -rf /var/cache/apk/*

RUN apk add --no-cache --virtual .run-deps rsync tzdata curl ca-certificates \
  && rm -rf /var/cache/apk/*

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["sh"]
