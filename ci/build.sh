#!/usr/bin/env bash

set -euxo pipefail

if [[ "${TRAVIS_BRANCH:-}" == "staging" ]]; then
  echo "Deploying to staging"
  REPO="${REPO_TEST}"
  AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID_TEST AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY_TEST \
  aws ecr get-login-password --region us-west-2 \
  | docker login --username AWS --password-stdin 811702477007.dkr.ecr.us-west-2.amazonaws.com
else
  aws ecr get-login-password --region us-west-2 \
  | docker login --username AWS --password-stdin 542640492856.dkr.ecr.us-west-2.amazonaws.com
fi

DOCKER_BUILD=${TRAVIS_BUILD_NUMBER:-0}

BRANCH=${TRAVIS_BRANCH:-local}
COMMIT_SHORT=${TRAVIS_COMMIT:0:7}

if [ -z "${COMMIT_SHORT:-}" ]
then
  COMMIT_SHORT=`git rev-parse --short HEAD`
fi

DOCKER_TAG=${COMMIT_SHORT}

BRANCH_DOCKER_TAG=${BRANCH}

# Build the Docker image in the subdirectory of the specified logstash version
docker build -t "${REPO}:${DOCKER_TAG}" .

# Add another Docker image by retagging the previously build container with the branch tag as well
docker tag "${REPO}:${DOCKER_TAG}" "${REPO}:${BRANCH_DOCKER_TAG}"