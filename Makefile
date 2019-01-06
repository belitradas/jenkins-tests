DOCKER_REGISTRY    ?= belitre
DOCKER_BUILD_FLAGS :=
LDFLAGS            :=

BINS        = mytests
IMAGES      = mytests
DOCKER_BINS = mytests

IMAGE_TAG ?= canary

HELM_VERSION = v2.10.0
HELM_DOWNLOAD_URL = https://storage.googleapis.com/kubernetes-helm/helm-$(HELM_VERSION)-linux-amd64.tar.gz

HELM_CHART_PATH ?= ./helm/demo

APP_NAME ?= blehbleh

TILLER_NAMESPACE ?= miguelsantiago

ENV_NAME ?= nonprod02

CONFIG_PATH := ./environments/$(ENV_NAME)/override.yaml

# Build native binaries
.PHONY: build
build: bootstrap
build: $(BINS)

.PHONY: $(BINS)
$(BINS):
	go build -o bin/$@ ./pkg/

# To use docker-build, you need to have Docker installed and configured. You should also set
# DOCKER_REGISTRY to your own personal registry if you are not pushing to the official upstream.
.PHONY: docker-build
docker-build: set-image-tag
	docker build $(DOCKER_BUILD_FLAGS) -t $(DOCKER_REGISTRY)/$(IMAGES):$(IMAGE_TAG) .

# You must be logged into DOCKER_REGISTRY before you can push.
.PHONY: docker-push
docker-push: docker-build
	docker push $(DOCKER_REGISTRY)/$(IMAGES):$(IMAGE_TAG)

.PHONY: helm-deploy
helm-deploy:
	helm upgrade --install $(APP_NAME) $(HELM_CHART_PATH) -f $(CONFIG_PATH) --tiller-namespace $(TILLER_NAMESPACE) --wait --timeout 45

.PHONY: helm-rollback
helm-rollback:
ifndef ROLLBACK_REVISION
	@echo "Error ROLLBACK_REVISION not defined"
	@exit 1
endif
	helm rollback $(APP_NAME) $(ROLLBACK_REVISION) --tiller-namespace $(TILLER_NAMESPACE) 

.PHONE: helm-delete
helm-delete:
	helm delete --purge $(APP_NAME) --tiller-namespace $(TILLER_NAMESPACE) 

HAS_DEP := $(shell command -v dep;)
HAS_HELM := $(shell command -v helm;)

.PHONY: bootstrap
bootstrap:
ifndef HAS_DEP
	go get -u github.com/golang/dep/cmd/dep
endif
	dep ensure -v

.PHONY: bootstrap-helm
bootstrap-helm:
ifndef HAS_HELM
	curl -L $(HELM_DOWNLOAD_URL) | tar xz && mv linux-amd64/helm /bin/helm && rm -rf linux-amd64
endif

set-image-tag:
ifdef GIT_SHORT_COMMIT
IMAGE_TAG = $(GIT_SHORT_COMMIT)
endif