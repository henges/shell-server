#!/bin/sh
USERNAME=$1
request_mode() {
    echo "SSE"
}

request_handler() {
    case $METHOD in
        'GET')
            echo "user_get_handler"
            ;;
        'POST')
            echo "user_post_handler"
            ;;
    esac
    # If we fell through to here, simply use echo to write an empty response.
    echo "echo"
}

user_get_handler() {
    for i in $(seq 1 30); do
        echo "Hello, $USERNAME! This is a GET request. Response: $i"
        sleep 1
    done
}

user_post_handler() {
    echo "Hello, $REQ_BODY! This is a POST request."
}
