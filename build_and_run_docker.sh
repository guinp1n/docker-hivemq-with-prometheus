#!/bin/bash

extension_name='hivemq-prometheus-extension'
MY_HIVEMQ_VERSION="latest"
MY_TAG="hivemq/hivemq4:$MY_HIVEMQ_VERSION-with-${extension_name}"

echo "Getting URL of the latest release of ${extension_name}..."
relative_url=$(curl --location --silent "https://github.com/hivemq/${extension_name}/releases/latest" \
  | grep "href=\".*${extension_name}[^/]*\\.zip" \
  | cut -d '"' -f 2)

echo "Downloading the latest release of ${extension_name}..."
rm "${extension_name}.zip" 2>/dev/null
curl --location --silent "https://github.com/${relative_url}" --output "${extension_name}.zip"
rm -r "${extension_name}" 2>/dev/null
unzip "${extension_name}.zip"
rm "${extension_name}.zip"


echo "Reading the Prometheus's target port from the HiveMQ Prometheus Extension's config file..."
prometheus_extension_port=$(grep --invert-match '^#' hivemq-prometheus-extension/prometheusConfiguration.properties \
  | grep 'port=' \
  | sed 's/port=//')
echo "  prometheus_extension_port = $prometheus_extension_port"


echo "Building a docker image for HiveMQ from $MY_HIVEMQ_VERSION with $extension_name. Then tagging as: $MY_TAG..."
docker build --build-arg TAG=$MY_HIVEMQ_VERSION --build-arg EXTENSION_NAME=$extension_name --tag $MY_TAG .

echo "Starting a docker container with HiveMQ with ${extension_name}..."
docker run --detach --name hivemq \
  --publish 8080:8080 \
  --publish 1883:1883 \
  --publish ${prometheus_extension_port}:${prometheus_extension_port} \
  --volume $(pwd)/hivemq-data:/opt/hivemq/data \
  --volume $(pwd)/hivemq-log:/opt/hivemq/log \
  ${MY_TAG}


echo "Writing to 'prometheus.yml'..."
#
# ATTENTION:
# The hostname 'host.docker.internal' will only work if you are running Docker Desktop for MacOS.
# If you are running Docker in a Linux, try using hostname 'localhost'.
# This refers to the 'targets' in the 'prometheus.yml' file:
#
#   targets:
#        - host.docker.internal:${prometheus_extension_port}
#
prometheus_yaml_content=$(cat <<EOF
global:
  scrape_interval: 5s
scrape_configs:
  - job_name: hivemq
    honor_timestamps: true
    scrape_interval: 15s
    scrape_timeout: 10s
    metrics_path: /metrics
    scheme: http
    static_configs:
      - targets:
        - host.docker.internal:${prometheus_extension_port}
EOF
)
echo "${prometheus_yaml_content}" > prometheus.yml


echo "Starting a docker container with Prometheus..."
docker run --detach --name prometheus \
  --publish 9090:9090 \
  --volume $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
  --volume $(pwd)/prometheus-volume:/prometheus \
  prom/prometheus


printf "Now wait while Prometheus starts working..."
until $(curl --output /dev/null --silent --head --fail "http://localhost:${prometheus_extension_port}/metrics"); do
    printf '  waiting 5s...'
    sleep 5
done
echo ''
echo "Prometheus GUI:
  http://localhost:9090"
echo "Available metrics of your HiveMQ in the Prometheus:
  http://localhost:${prometheus_extension_port}/metrics"


echo "Starting a docker container with Grafana..."
docker run --detach --name grafana \
  --publish 3000:3000 \
  --volume $(pwd)/grafana-provisioning:/etc/grafana/provisioning/ \
  --volume $(pwd)/grafana-dashboards/hivemq-dashboard.json:/var/lib/grafana/dashboards/hivemq-dashboard.json \
  grafana/grafana-enterprise

echo "Grafana GUI:
  http://localhost:3000
(default username:password = admin:admin)"