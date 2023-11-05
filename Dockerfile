FROM alpine:latest

WORKDIR /app

RUN apk update
RUN apk add \
    curl \
    yq \
    busybox-extras
RUN apk add nano

COPY register-http-service.sh handler-wrapper.sh ./

RUN chmod +x *.sh

ENTRYPOINT ["/bin/sh", "/app/run.sh"]
