ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.0.0-old
FROM $BASE_IMG

COPY br /br
