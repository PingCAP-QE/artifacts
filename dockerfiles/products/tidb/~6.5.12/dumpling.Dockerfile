ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.10.1
FROM $BASE_IMG

COPY dumpling /dumpling
