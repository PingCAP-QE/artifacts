ARG BASE_IMG=hub.pingcap.net/bases/tools-base:v1.7.0
FROM $BASE_IMG
COPY dumpling /dumpling
