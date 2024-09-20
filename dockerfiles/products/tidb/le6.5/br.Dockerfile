ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.0.1-old
FROM $BASE_IMG

COPY br /br
