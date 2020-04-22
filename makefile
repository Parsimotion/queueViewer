APP=qviewer
REGISTRY_PREFIX=producteca-jobs
BUILD_FOLDER=.
LAST_COMMIT= $(shell git rev-parse HEAD)
IMAGE = $(APP):$(LAST_COMMIT)
REMOTE = productecaregistry.azurecr.io
IMAGE_REMOTE = $(REMOTE)/$(REGISTRY_PREFIX)/$(IMAGE)

deploy: build-image upload-acr

build-image:
	cd $(BUILD_FOLDER) && docker build -t $(IMAGE) .

local: build-image local-docker 

local-docker:
	iwannabe $(APP) --k8s --format=docker
	docker run --rm --env-file=site.config -p9000:9000 $(IMAGE)

upload-acr:
	docker tag $(IMAGE) $(IMAGE_REMOTE)
	docker push $(IMAGE_REMOTE)

.PHONY: deploy
