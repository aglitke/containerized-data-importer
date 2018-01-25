REPO_ROOT=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# Binary Output
BIN_DIR=$(REPO_ROOT)/bin
CONTROLLER_BIN=$(BIN_DIR)/import-controller
IMPORTER_BIN=$(BIN_DIR)/vm-importer

# Source dirs
CMD_DIR=$(REPO_ROOT)/cmd
CONTROLLER_CMD=$(CMD_DIR)/controller
IMPORTER_CMD=$(CMD_DIR)/importer

# Build Dirs
BUILD_DIR=$(REPO_ROOT)/build
CONTROLLER_BUILD=$(BUILD_DIR)/controller
IMPORTER_BUILD=$(BUILD_DIR)/importer

# DOCKER TAG VARS
REGISTRY=gcr.io/openshift-gce-devel
CONTROLLER_IMAGE=import-controller
IMPORTER_IMAGE=vm-importer
DIRTY_HASH=$(shell git describe --always --abbrev=7 --dirty)
VERSION=v1

.PHONY: controller controller_image vm_importer vm_importer_image clean #release push
all: clean controller controller_image importer importer_image

# Compile controller binary
controller:
	go build -i -o $(CONTROLLER_BIN) $(CONTROLLER_CMD)/*.go

# Compile importer binary
importer:
	go build -i -o $(IMPORTER_BIN) $(IMPORTER_CMD)/*.go

# build the controller image
controller_image: $(CONTROLLER_BUILD)/Dockerfile
	$(eval TEMP_BUILD_DIR=$(CONTROLLER_BUILD)/tmp)
	mkdir -p $(TEMP_BUILD_DIR)
	cp $(CONTROLLER_BIN) $(TEMP_BUILD_DIR)
	cp $(CONTROLLER_BUILD)/Dockerfile $(TEMP_BUILD_DIR)
	docker build -t $(CONTROLLER_IMAGE) $(TEMP_BUILD_DIR)
	docker tag $(CONTROLLER_IMAGE) $(REGISTRY)/$(CONTROLLER_IMAGE):$(DIRTY_HASH)
	rm -rf $(TEMP_BUILD_DIR)

# build the controller image
importer_image: $(IMPORTER_BUILD)/Dockerfile
	$(eval TEMP_BUILD_DIR=$(IMPORTER_BUILD)/tmp)
	mkdir -p $(TEMP_BUILD_DIR)
	cp $(IMPORTER_BIN) $(TEMP_BUILD_DIR)
	cp $(IMPORTER_BUILD)/Dockerfile $(TEMP_BUILD_DIR)
	docker build -t $(CONTROLLER_IMAGE) $(TEMP_BUILD_DIR)
	docker tag $(IMPORTER_IMAGE) $(REGISTRY)/$(IMPORTER_IMAGE):$(DIRTY_HASH)
	rm -rf $(TEMP_BUILD_DIR)

clean:
	-rm -rf $(BIN_DIR)/*
	-rm -rf $(CONTROLLER_BUILD)/tmp
	-rm -rf $(IMPORTER_BUILD)/tmp

# TODO add image specific push options
# push CONTROLLER_IMAGE:$(VERSION). Intended to release stable image built from master branch.
#release:
#	git fetch origin
#ifneq ($(shell git rev-parse --abbrev-ref HEAD), master)
#	$(error Release is intended to be run on master branch. Please checkout master and retry.)
#endif
#ifneq ($(shell git rev-list HEAD..origin/master --count), 0)
#	$(error HEAD is behind origin/master -- $(shell git status -sb --porcelain))
#endif
#ifneq ($(shell git rev-list origin/master..HEAD --count), 0)
#	$(error HEAD is ahead of origin/master --  $(shell git status -sb --porcelain))
#endif
#	docker tag $(IMAGE) $(REGISTRY)/$(CONTROLLER_IMAGE):$(VERSION)
#	gcloud docker -- push $(REGISTRY)/$(CONTROLLER_IMAGE)