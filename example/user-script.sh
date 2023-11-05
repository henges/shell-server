#!/bin/sh
USER_NAME=$1
user_get_handler() {
    echo "hey $USER_NAME"
}

user_get_request_mode() {
    echo "CHUNKED"
}

user_post_handler() {
    echo "hello $REQ_BODY"
}
