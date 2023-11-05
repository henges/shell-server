FROM alpine:latest

WORKDIR /app

RUN apk update
RUN apk add \
    curl \
    yq \
    busybox-extras
RUN apk add nano

COPY src/*.sh ./

RUN chmod +x *.sh

ENTRYPOINT ["/app/run.sh"]
