docker stop shell-server
docker build -t shell-server:latest .
docker run --rm -d --name "shell-server" -p 8181:8080 shell-server
