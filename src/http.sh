#!/bin/sh
# This should have been called with any arguments to the user's script
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
    # Weirdly `seq` seems unable to parse the content length
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
    echo "Access-Control-Allow-Methods: GET, OPTIONS"
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

handle_get_request_plain() {
    body=$(user_get_handler)
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
        sleep 1
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

    write_default_headers
    echo "Transfer-Encoding: chunked"
    echo "X-Content-Type-Options: nosniff"
    echo
    # Create a file that the result will be written to
    filename="/tmp/application-$(date +%s)-data" 
    touch "$filename"
    # Run a background process for the result
    user_get_handler > "$filename" 2>&1 &
    handler_pid=$!
    sleep 1
    poll_for_chunks "$handler_pid" "$filename"
    printf '\r\n'
    rm "$filename"
}

handle_get_request() {
    mode="default"
    if command -v user_get_request_mode &> /dev/null; then
        mode=$(user_get_request_mode)
    fi
    case $mode in
        'CHUNKED')
            handle_request_chunked
            ;;
        *)
            handle_get_request_plain
            ;;
    esac
}

# TODO: it's almost identical to the plain get handler.
# We can DRY this up probably.
handle_post_request() {
    body=$(user_post_handler)
    length=$(echo "$body" | wc -c)

    write_default_headers
    echo "Content-Length: $length"
    echo
    echo "$body"
}

case $METHOD in
    'OPTIONS')
        handle_options_request
        ;;
    'GET')
        handle_get_request
        ;;
    'POST')
        handle_post_request
        ;;
esac
