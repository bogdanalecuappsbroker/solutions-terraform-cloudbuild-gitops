# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM gcr.io/cloud-builders/gcloud-slim

ARG TERRAFORM_VERSION=0.12.26
ARG TERRAFORM_VERSION_SHA256SUM=607bc802b1c6c2a5e62cc48640f38aaa64bef1501b46f0ae4829feb51594b257
ARG TERRAGRUNT_VERSION=0.23.31

ENV ENV_TERRAFORM_VERSION=$TERRAFORM_VERSION
ENV ENV_TERRAFORM_VERSION_SHA256SUM=$TERRAFORM_VERSION_SHA256SUM
ENV TERRAGRUNT_VERSION=$TERRAGRUNT_VERSION

RUN apt-get update && \
   /builder/google-cloud-sdk/bin/gcloud -q components install alpha beta && \
    apt-get -y install curl wget jq unzip ca-certificates && \
    curl https://releases.hashicorp.com/terraform/${ENV_TERRAFORM_VERSION}/terraform_${ENV_TERRAFORM_VERSION}_linux_amd64.zip \
      > terraform_linux_amd64.zip && \
    echo "${ENV_TERRAFORM_VERSION_SHA256SUM} terraform_linux_amd64.zip" > terraform_SHA256SUMS && \
    sha256sum -c terraform_SHA256SUMS --status && \
    unzip terraform_linux_amd64.zip -d /builder/terraform && \
    rm -f terraform_linux_amd64.zip && \
    mkdir -p /builder/terragrunt && \
    wget https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 -O /builder/terragrunt/terragrunt && \
    chmod +x /builder/terragrunt/terragrunt && \
    apt-get remove --purge -y curl unzip wget && \
    apt-get --purge -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PATH=/builder/terraform/:$PATH
ENV PATH=/builder/terragrunt/:$PATH
COPY entrypoint.bash /builder/entrypoint.bash
ENTRYPOINT ["/builder/entrypoint.bash"]
