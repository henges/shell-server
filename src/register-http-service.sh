#!/bin/sh

SERVICE_NAME=$1
SERVICE_PORT=$2
# HANDLER_SCRIPT=$3
shift; shift; 
# shift;
HANDLER_ARGS="$@"

register_service() {
    service_definition=$(printf "%s\t%s/tcp\n" "$SERVICE_NAME" "$SERVICE_PORT")
    if ! grep -q "$service_definition" /etc/services; then
        echo "$service_definition" >> /etc/services;
    fi
    touch /etc/inetd.conf
    inetd_definition=$(printf "%s stream tcp nowait root /bin/sh sh /app/http.sh %s\n" "$SERVICE_NAME" "$HANDLER_ARGS") 
    if ! grep -q "$inetd_definition" /etc/inetd.conf; then
        echo "$inetd_definition" >> /etc/inetd.conf;
    fi
}

register_service
