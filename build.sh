#!/usr/bin/env bash

sudo podman build \
  -t metals-example \
  -t quay.io/freedomben/metals-example \
  -t docker.io/freedomben/metals-example \
  .
