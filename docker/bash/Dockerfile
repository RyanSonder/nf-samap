# docker/bash/Dockerfile
FROM docker.io/ubuntu:jammy

# Copy scripts into the container's bin directory
COPY bin/verify_samplesheet.sh /usr/local/bin/verify_samplesheet.sh

# Make sure it’s executable
RUN chmod +x /usr/local/bin/verify_samplesheet.sh 

WORKDIR /workspace