ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.11.0
FROM $BASE_IMG

COPY br /br
