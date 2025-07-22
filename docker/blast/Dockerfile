# docker/blast/Dockerfile
FROM docker.io/staphb/blast:latest

# Copy scripts into the container's bin directory
COPY bin/map_genes.sh /usr/local/bin/map_genes.sh

# Make sure it’s executable
RUN chmod +x /usr/local/bin/map_genes.sh 

WORKDIR /workspace