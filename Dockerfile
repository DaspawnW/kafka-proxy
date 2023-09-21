FROM grepplabs/kafka-proxy:0.3.6

USER root

RUN apk add bind-tools jq

COPY startup /opt/startup
RUN chmod +x /opt/startup/start.sh && \
    chown kafka-proxy:kafka-proxy /opt/startup/start.sh

USER kafka-proxy

ENTRYPOINT ["/opt/startup/start.sh"]
