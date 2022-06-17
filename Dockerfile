ARG TAG=latest
ARG EXTENSION_NAME=hivemq-prometheus-extension

FROM hivemq/hivemq4:${TAG}
#ENV HIVEMQ_CLUSTER_PORT 8000

COPY --chown=hivemq:hivemq hivemq-config.xml /opt/hivemq/conf/config.xml
COPY --chown=hivemq:hivemq ${EXTENSION_NAME} /opt/hivemq/extensions/${EXTENSION_NAME}
