ARG arch=x86_64
FROM multiarch/alpine:${arch}-latest

RUN apk add --no-cache curl jq

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

HEALTHCHECK --interval=5s CMD exit 0

CMD ["autoheal"]