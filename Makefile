MAKEFILES_VERSION=9.5.3

.DEFAULT_GOAL:=help

include build/make/variables.mk
include build/make/self-update.mk
include build/make/release.mk
include build/make/clean.mk
include build/make/k8s-dogu.mk
include build/make/bats.mk

.PHONY: clean-k8s
clean-k8s:
	@kubectl delete -f ${WORKDIR}/k8s/*.yaml || true
