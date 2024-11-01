﻿# Devops-Scripts

## Overview

Welcome to the **Devops-Scripts** repository! This repository contains a collection of scripts aimed at simplifying the installation and management of essential DevOps tools and applications. Currently, it focuses on automating the setup of **Node Exporter** and **Prometheus**, two critical components for monitoring and alerting in a cloud-native environment.

## Purpose

The primary goal of this repository is to serve as a starting point for deploying and managing necessary DevOps applications with minimal manual intervention. These scripts are designed for long-term use, ensuring a streamlined setup process for users and teams.

## Included Scripts

### 1. Node Exporter Installation Script

This script automates the installation of Node Exporter, which provides hardware and OS metrics from the host machine, making it easier to monitor system performance.

### 2. Prometheus Installation Script

This script installs Prometheus, an open-source monitoring and alerting toolkit. Prometheus collects and stores metrics data, allowing users to query and visualize performance metrics.

## Prerequisites

Before running the scripts, ensure you have the following:

- A Linux-based operating system (e.g., Ubuntu, CentOS)
- Required packages:
  - `curl` for fetching the latest version information
  - `jq` for parsing JSON data
  - `wget` for downloading files
  - `htpasswd` for creating hashed passwords

You can install the required packages using:

```bash
sudo apt-get update
sudo apt-get install -y curl jq wget apache2-utils
```

## Usage

### Installing Node Exporter

To install Node Exporter, run the following command:

```bash
bash <(curl -s https://raw.githubusercontent.com/abdulsaheel/Devops-Scripts/refs/heads/main/node_exporter_setup.sh)
```

### Installing Prometheus

To install Prometheus, run:

```bash
bash <(curl -s https://raw.githubusercontent.com/abdulsaheel/Devops-Scripts/refs/heads/main/prometheus_setup.sh)
```

### Configuration

- **Node Exporter** will be accessible at `http://127.0.0.1:9100`.
- **Prometheus** will have a web interface that you can access. You can authenticate using the admin username and the password set in the `ADMIN_PASSWORD` environment variable (default: `password`).

### Systemd Services

Both Node Exporter and Prometheus are set up as systemd services, which ensures they start automatically on boot. You can manage these services using the following commands:

- Check the status of the services:
  ```bash
  sudo systemctl status node_exporter
  sudo systemctl status prometheus
  ```

- Start or stop the services:
  ```bash
  sudo systemctl start node_exporter
  sudo systemctl stop node_exporter
  sudo systemctl start prometheus
  sudo systemctl stop prometheus
  ```

## Contributing

Contributions are welcome! If you have suggestions for improvements or additional scripts to add, please create an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

Thanks to the developers of Node Exporter and Prometheus for their contributions to the monitoring and observability landscape.

