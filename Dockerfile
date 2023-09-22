FROM ghcr.io/daspawnw/kafka-proxy-fk:27fc225254ae7319039c6fd4d1ba458d24bb4a84

USER root

RUN apk add bind-tools jq

COPY startup /opt/startup
RUN chmod +x /opt/startup/start.sh && \
    chown kafka-proxy:kafka-proxy /opt/startup/start.sh

USER kafka-proxy

ENTRYPOINT ["/opt/startup/start.sh"]
