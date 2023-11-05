#!/bin/sh

HANDLER_SCRIPT=$1
shift
HANDLER_ARGS="$@"

# Request parsing based on:
# https://gist.github.com/robspassky/1959319
read request
method=$(echo "$request" | cut -f 1 -d ' ')

while /bin/true; do
        read header
        [ "$header" = "$(printf '\r')" ] && break
        header_name=$(echo "$header" | cut -f 1 -d ':')
        case "$header_name" in
            'Origin')
                origin=$(echo "$header" | cut -f 2- -d ':' | tr -d ' ')
                ;;
        esac
done

write_ac_headers() {
    # Origin must match the one in the request when auth is being used
    echo "Access-Control-Allow-Origin: ${origin:-*}"
    echo "Access-Control-Allow-Methods: GET, OPTIONS"
    echo "Access-Control-Allow-Headers: Content-Type, Authorization"
    echo "Access-Control-Allow-Credentials: true"
}

write_default_get_headers() {

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

handle_get_request() {

    body=$(sh "$HANDLER_SCRIPT" "$HANDLER_ARGS")
    length=$(echo "$body" | wc -c)

    write_default_get_headers
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

handle_get_request_chunked() {

    write_default_get_headers
    echo "Transfer-Encoding: chunked"
    echo
    # Create a file that the result will be written to
    filename="/tmp/application-$(date +%s)-data" 
    touch "$filename"
    # Run a background process for the result
    sh "$HANDLER_SCRIPT" "$HANDLER_ARGS" > "$filename" 2>&1 &
    handler_pid=$!
    sleep 1
    poll_for_chunks "$handler_pid" "$filename"
    printf '\r\n'
}

case $method in
    'OPTIONS')
        handle_options_request
        ;;
    'GET')
        handle_get_request_chunked
        ;;
esac
