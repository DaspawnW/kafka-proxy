FROM grepplabs/kafka-proxy:0.3.6

USER root

RUN apk add bind-tools jq

USER kafka-proxy

COPY startup /opt/startup

ENTRYPOINT ["/opt/startup/start.sh"]
