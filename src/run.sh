#! /bin/sh
HANDLER_ARGS=$@

if ! stat "/app/user-script.sh" > /dev/null 2>&1; then
    echo "ERROR: You need to define a user script to use as a request handler."
    echo "Please try adding such a file at path /app/user-script.sh (for instance, through a container volume mount) and try again."
    return 1
fi

./register-http-service.sh "shell-server" "8080" "$HANDLER_ARGS"

inetd

# The runtime is unwilling to kill the process this script
# is running as (PID 1), so calling 'sleep infinity' directly
# prevents the process from responding to SIGTERM.
# Instead we need a child process to help receive those signals.
# Based on answer from here: https://stackoverflow.com/a/39128574
# Start a child process that sleeps indefinitely
sleep infinity & PID=$!
# Kill this process when we receive SIGINT/TERM
trap "kill $PID" INT TERM

# Wait for that process to quit 
wait

echo "Daemon quit"
