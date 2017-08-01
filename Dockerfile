FROM alpine:3.6

RUN apk --update --no-cache add openldap openldap-clients
COPY entrypoint.sh /entrypoint.sh
COPY initialize.sh /initialize.sh

EXPOSE 389

CMD ["/entrypoint.sh"]
