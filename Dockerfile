# Dockerfile to test both Node Exporter and Prometheus together

# Use a base image (e.g., Ubuntu 20.04)
FROM ubuntu:20.04

# Set environment variable to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget curl systemctl && \
    apt-get clean

# Copy the Node Exporter and Prometheus setup scripts to the container
COPY node_exporter_setup.sh /usr/local/bin/node_exporter_setup.sh
COPY prometheus_setup.sh /usr/local/bin/prometheus_setup.sh

# Make the scripts executable
RUN chmod +x /usr/local/bin/node_exporter_setup.sh /usr/local/bin/prometheus_setup.sh

# Run both setup scripts to install and configure Node Exporter and Prometheus
RUN /usr/local/bin/node_exporter_setup.sh && \
    /usr/local/bin/prometheus_setup.sh

# Expose ports for Prometheus and Node Exporter
EXPOSE 9090 9100

# Start Node Exporter and Prometheus with specified configurations
CMD /usr/local/bin/node_exporter --web.listen-address="0.0.0.0:9100" & \
    /usr/local/bin/prometheus --config.file=/etc/prometheus/exporter.yml
