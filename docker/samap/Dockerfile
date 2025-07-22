# docker/samap/Dockerfile
FROM docker.io/avianalter/samap:latest

# Copy scripts into the container's bin directory
COPY bin/visualize_samap.py /usr/local/bin/visualize_samap.py
COPY bin/build_samap.py /usr/local/bin/build_samap.py
COPY bin/run_samap.py /usr/local/bin/run_samap.py
COPY bin/log_utils.py /usr/local/bin/log_utils.py
COPY bin/load_sam.py /usr/local/bin/load_sam.py

# Make sure it’s executable
RUN chmod +x /usr/local/bin/visualize_samap.py
RUN chmod +x /usr/local/bin/build_samap.py 
RUN chmod +x /usr/local/bin/run_samap.py 
RUN chmod +x /usr/local/bin/log_utils.py 
RUN chmod +x /usr/local/bin/load_sam.py 

WORKDIR /workspace