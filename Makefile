# Set these to the desired values
ARTIFACT_ID=k8s-static-webserver
VERSION=0.0.0

MAKEFILES_VERSION=6.0.3

## Image URL to use all building/pushing image targets
IMAGE_DEV=${K3CES_REGISTRY_URL_PREFIX}/${ARTIFACT_ID}:${VERSION}
IMAGE=cloudogu/${ARTIFACT_ID}:${VERSION}

K8S_RESOURCE_DIR=${WORKDIR}/k8s
K8S_WEBSERVER_RESOURCE_YAML=${K8S_RESOURCE_DIR}/k8s-static-webserver.yaml

include build/make/variables.mk
include build/make/self-update.mk
include build/make/clean.mk
include build/make/k8s.mk

##@ EcoSystem

.PHONY: build
build: k8s-delete image-import set-always-pull-strategy k8s-apply ## Builds a new version of the static webserver and deploys it into the K8s-EcoSystem.

.PHONY: set-always-pull-strategy
set-always-pull-strategy:
	@$(BINARY_YQ) -i e "(select(.kind == \"Deployment\").spec.template.spec.containers[]|select(.image == \"*$(ARTIFACT_ID)*\").imagePullPolicy)=\"Always\"" $(K8S_RESOURCE_TEMP_YAML)

.PHONY: k8s-create-temporary-resource
k8s-create-temporary-resource:
	@cat $(K8S_WEBSERVER_RESOURCE_YAML) > $(K8S_RESOURCE_TEMP_YAML)

##@ Release

.PHONY: server-release
server-release: ## Interactively starts the release workflow.
	@echo "Starting git flow release..."
	@build/make/release.sh static-webserver
