FROM alpine:latest

RUN apk add --no-cache curl jq

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

HEALTHCHECK --interval=5s CMD exit 0

CMD ["autoheal"]
