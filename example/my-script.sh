#!/bin/sh
source /app/http.sh

case $METHOD in
    'OPTIONS')
        handle_options_request
        ;;
    'GET')
        handle_get_request_chunked "/app/script-body.sh"
        ;;
esac
