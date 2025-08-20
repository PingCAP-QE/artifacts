ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.10.0
FROM $BASE_IMG

COPY cdc /cdc

EXPOSE 8300
CMD [ "/cdc" ]
