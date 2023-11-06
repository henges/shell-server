# shell-server

`shell-server` is a baseline script that allows developing simple HTTP interfaces to shell scripts. It's intended primarily for creating shims around existing scripts, allowing for remote invocation of a program that would otherwise require the calling device to have an SSH client.

> Note that `shell-server` is currently missing several features that would be expected of a production-ready application and is not recommended for use in these contexts.

## Overview

### Using it
This application expects user code to be contained in a file located at `/app/user-script.sh`. This file should define a function named `request_handler` that returns the _name_ of another function to invoke to produce the response body for a given request. The response body producer should write the result directly to `stdout`; the application will handle writing the appropriate headers to the response. You can find an example of this in the `example` directory.

> When your `request_handler` is invoked, any output to `stderr` it produces will be written to the response, even before the HTTP headers are written. Most HTTP clients will (rightly) reject this response as malformed, so ensure this section of code is fault-tolerant.

Additionally, chunked encoding or server-sent events may be used to write the response (for example, if the script you call is long-running and you want to stream its output to the client). To configure this, define a function named `request_mode` that determines how a given request should be delivered to the client. This function should return the sentinel value `"CHUNKED"` for chunked encoding or `"SSE"` for server-sent events.

The following variables are available for use in functions within `user-script.sh`:
- `METHOD`: contains the name of the HTTP method of the current request
- `REQ_BODY`: if applicable, contains the HTTP request body

Your script may require additional arguments, such as the location of secret data. To facilitate this, any arguments to `run.sh` will be proxied through to `user-script.sh`. 

### Components
- `run.sh` is the container's entrypoint for the program. It's a daemon that registers `shell_server` with `inetd` as a handler of TCP connections on port `8080` and sleeps until the container quits.
- `register-http-service.sh` contains logic for registering the server binding with `inetd`.
- `http.sh` is the entrypoint for incoming TCP connections. It assumes the connection is sending an HTTP request, parses it, calls the user's script to determine which function to invoke to produce the response, and then invokes that function using the appropriate transfer encoding.
