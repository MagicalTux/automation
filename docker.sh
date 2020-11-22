#!/bin/sh

export DOCKER_BUILDKIT=1

# Script to build docker image
docker build -t karpeleslab/phpbase:latest .
