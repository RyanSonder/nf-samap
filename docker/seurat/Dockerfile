# docker/seurat/Dockerfile
FROM docker.io/mdiblbiocore/seurat:latest

# Copy scripts into the container's bin directory
COPY bin/rds_to_h5ad.R /usr/local/bin/rds_to_h5ad.R

# Make sure it’s executable
RUN chmod +x /usr/local/bin/rds_to_h5ad.R

WORKDIR /workspace