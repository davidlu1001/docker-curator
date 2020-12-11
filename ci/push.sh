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

if [[ -z "${REPO}" ]];
then
    REPO="542640492856.dkr.ecr.us-west-2.amazonaws.com/curator"
fi

docker push "${REPO}"