ARG BASE=hub.pingcap.net/bases/tools-base:v1.7.0
FROM $BASE
COPY dumpling /dumpling
