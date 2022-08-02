#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
# This script is automatically called by the automatic git flow release process. It is responsible to change the
# version of the image in the K8s deployment resource `k8s/k8s-static-webserver.yaml` to the newest one.
K8S_STATIC_WEBSERVER_YAML=k8s/k8s-static-webserver.yaml

update_versions_modify_files() {
  newReleaseVersion="${1}"
  newImage="cloudogu/k8s-static-webserver:${newReleaseVersion}"

  yq e "(select(.kind == \"Deployment\").spec.template.spec.containers[]|select(.name == \"k8s-static-webserver\")).image=\"${newImage}\"" \
    ${K8S_STATIC_WEBSERVER_YAML} > tmpfile

  mv tmpfile "${K8S_STATIC_WEBSERVER_YAML}"
}

update_versions_stage_modified_files() {
  git add "${K8S_STATIC_WEBSERVER_YAML}"
}