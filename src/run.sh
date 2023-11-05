#! /bin/sh
SERVICE_NAME=$1
SEVICE_PORT=$2
HANDLER_PATH=$3
shift; shift; shift
HANDLER_ARGS=$@

chmod +x "$HANDLER_PATH"

./register-http-service.sh "$SERVICE_NAME" "$SERVICE_PORT" "$HANDLER_PATH" "$HANDLER_ARGS"

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
