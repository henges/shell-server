FROM alpine:latest

WORKDIR /app

RUN apk update
RUN apk add \
    curl \
    yq \
    busybox-extras
RUN apk add nano

COPY src/register-http-service.sh src/handler-wrapper.sh ./

RUN chmod +x *.sh

ENTRYPOINT ["/bin/sh"]
