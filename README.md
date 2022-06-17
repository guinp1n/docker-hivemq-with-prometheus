This project is inspired by the HiveMQ blog article [HiveMQ - Monitoring with Prometheus and Grafana](https://www.hivemq.com/blog/monitoring-hivemq-prometheus/).

This project contains the script that runs in Docker the following containers:
- HiveMQ with HiveMQ-Prometheus-Extension
- Prometheus
- Grafana

### Disclaimer

This script is tested only with MacOS and Docker Desktop for Mac! To make it work in Linux you will need to modify the script (see section 'For non-MacOs users').

# Quick start

1. Make sure you have Docker or Docker Desktop installed.
2. Clone this project to a directory.
3. Open a Terminal and change to the project's root directory:

```cd docker-hivemq-with-prometheus```
4. Run the script from the project's root directory:

```
./build_and_run_docker.sh
```

If everything works, you will have 
- HiveMQ Control Center at http://localhost:8080
- Metrics of the HiveMQ available in Prometheus at http://localhost:9399/metrics
- Prometheus GUI at http://localhost:9090
- Grafana GUI at http://localhost:3000

## For non-MacOS users
This script is generating a 'prometheus.yml' configuration file. This file will contain the scraping target for Prometheus that looks like this:
```
- targets:
    - host.docker.internal:9399
```
The hostname `host.docker.internal` is only correct for the Docker Desktop for Mac. If you are in Linux then you probably need to use `localhost:9399` (I didn't test, but if you do please enlight me).