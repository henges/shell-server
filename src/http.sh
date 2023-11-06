#!/bin/sh
# This file should have been called with any arguments to the user's script,
# so simply proxy them through.
source /app/user-script.sh "$@"

# Request parsing based on:
# https://gist.github.com/robspassky/1959319
read request
export METHOD=$(echo "$request" | cut -f 1 -d ' ')

has_body=1
while /bin/true; do
    read header
    [ "$header" = "$(printf '\r')" ] && break
    header_name=$(echo "$header" | cut -f 1 -d ':')
    case "$header_name" in
        'Origin')
            origin=$(echo "$header" | cut -f 2- -d ':' | tr -d ' ')
            ;;
        'Content-Length')
            content_length=$(echo -n "$header" | cut -f 2- -d ':' | tr -d ' ')
            has_body=0
            ;;
    esac
done

req_body=""
if test 0 -eq $has_body; then
    # `seq` seems unable to parse the content length
    # unless you explicitly make it a number like this
    content_length=$((content_length + 0))
    for i in $(seq 1 "$content_length"); do
        read -n 1 char
        req_body="$req_body$char"
    done
fi
export REQ_BODY="$req_body"

write_ac_headers() {
    # Origin must match the one in the request when auth is being used
    echo "Access-Control-Allow-Origin: ${origin:-*}"
    echo "Access-Control-Allow-Methods: GET, POST, OPTIONS"
    echo "Access-Control-Allow-Headers: Content-Type, Authorization"
    echo "Access-Control-Allow-Credentials: true"
}

write_default_headers() {

    echo "HTTP/1.1 200 OK"
    echo "Connection: close"
    echo "Content-Type: text/plain"
    write_ac_headers
}

handle_options_request() {
    echo "HTTP/1.1 204 No Content"
    write_ac_headers
    echo "Connection: keep-alive"
}

handle_request_plain() {
    request_handler=$(request_handler)
    body=$($request_handler)
    length=$(echo "$body" | wc -c)

    write_default_headers
    echo "Content-Length: $length"
    echo
    echo "$body"
}

offset=0

poll_for_chunks() {
    pid=$1
    filename=$2
    while true; do
        if ! kill -s 0 "$pid" 2>/dev/null; then
            should_break=0
        else
            should_break=1
        fi
        write_chunk
        if test 0 -eq "$should_break"; then 
            break;
        fi
        sleep 0.5
    done
    write_chunk
    printf '0\r\n'
}

write_chunk() {
    current_resp=$(tail -c +"$offset" "$filename")
    len_bytes=$(echo -n "$current_resp" | wc -c)
    if test "$len_bytes" -gt 0; then
        # Write a chunk to the output stream
        printf "%x\r\n%s\r\n" "$len_bytes" "$current_resp"
        offset=$((offset + len_bytes + 1))
    fi
}

handle_request_chunked() {

    request_handler=$(request_handler)
    write_default_headers
    echo "Transfer-Encoding: chunked"
    echo "X-Content-Type-Options: nosniff"
    echo
    # Create a file that the result will be written to
    filename="/tmp/application-$(date +%s)-data" 
    touch "$filename"
    # Run a background process for the result
    $request_handler > "$filename" 2>&1 &
    handler_pid=$!
    poll_for_chunks "$handler_pid" "$filename"
    printf '\r\n'
    rm "$filename"
}

handle_request_eventstream() {

    request_handler=$(request_handler)
    echo "HTTP/1.1 200 OK"
    echo "Connection: keep-alive"
    echo "Content-Type: text/event-stream"
    write_ac_headers
    echo
    $request_handler | while read line; do 
        printf "data: %s\r\n" "$line" 
    done
}

handle_request() {
    mode="default"
    if command -v request_mode &> /dev/null; then
        mode=$(request_mode)
    fi
    case $mode in
        'CHUNKED')
            handle_request_chunked 
            ;;
        'SSE')
            handle_request_eventstream
            ;;
        *)
            handle_request_plain
            ;;
    esac
}

case $METHOD in
    'OPTIONS')
        handle_options_request
        ;;
    *)
        handle_request
        ;;
esac
