ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pingcap-base:v1.9.2
FROM $BASE_IMG
COPY br /br
