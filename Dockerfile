FROM alpine:latest

WORKDIR /app

RUN apk update
RUN apk add \
    curl \
    yq \
    busybox-extras
RUN apk add nano

COPY src/*.sh example/*.sh ./

RUN chmod +x *.sh

ENTRYPOINT ["/bin/sh", "/app/run.sh", "/app/my-script.sh"]
