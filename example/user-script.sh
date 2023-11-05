#!/bin/sh
USERNAME=$1
request_mode() {
    echo "CHUNKED"
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
    echo "Hello, $USERNAME! This is a GET request."
}

user_post_handler() {
    echo "Hello, $REQ_BODY! This is a POST request."
}
