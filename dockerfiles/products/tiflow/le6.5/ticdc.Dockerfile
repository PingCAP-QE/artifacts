ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tiflow-base:v1.0.0-old
FROM $BASE_IMG

COPY cdc /cdc
EXPOSE 8300
CMD [ "/cdc" ]
