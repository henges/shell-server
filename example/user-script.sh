#!/bin/sh
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
}

user_get_handler() {
    echo "hey bro"
}

user_post_handler() {
    echo "hello $REQ_BODY"
}
