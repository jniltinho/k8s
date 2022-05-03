#!/usr/bin/env bash

# set -ex

set -e

## Build
docker build --no-cache -t ghcr.io/jniltinho/dind-alpine-k8s .

## Test
# docker run -t -i -v /var/run/docker.sock:/var/run/docker.sock --rm dind-alpine-k8s bash
