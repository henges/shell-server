docker stop shell-server
docker build -t shell-server:latest .
docker run --rm -d --entrypoint="/bin/sh" --name "shell-server" shell-server -c "sleep infinity"
