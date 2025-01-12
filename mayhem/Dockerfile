# Build Stage:
FROM --platform=linux/amd64 ubuntu:20.04 as builder

## Install build dependencies.
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y build-essential libcurl4-gnutls-dev


## Add Source Code
ADD *.c /
ADD *.h /
ADD *.1 /
ADD Makefile /

## Build Step
RUN make

# Package Stage
FROM --platform=linux/amd64 ubuntu:20.04
COPY --from=builder /trurl /
RUN apt-get update && apt install -y libcurl3-gnutls
