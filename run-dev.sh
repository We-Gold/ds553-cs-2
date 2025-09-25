# Remove all old containers
docker ps -a --filter ancestor=ds553-cs1 -q | xargs -r docker rm

# Build and run the container
docker build -t ds553-cs1 .
docker run -p 7860:7860 ds553-cs1