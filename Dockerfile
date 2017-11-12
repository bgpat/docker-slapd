FROM alpine:3.6

RUN apk -U --no-cache add openldap
COPY entrypoint.sh /entrypoint.sh

EXPOSE 389 636

ENTRYPOINT ["/entrypoint.sh"]
