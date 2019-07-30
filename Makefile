.DEFAULT_GOAL := help

#### Constant variables
# use -count=1 to disable cache and -p=1 to stream output live
# EXPORTVAR := export APPSODY_STACKS=incubator/nodejs-express,incubator/java-microprofile
EXPORTVAR := export APPSODY_STACKS=incubator/nodejs-express
GO_TEST_COMMAND := go test -v -count=1 -p=1
# Set a default VERSION only if it is not already set
VERSION ?= 0.0.0
COMMAND := appsody
BUILD_PATH := $(PWD)/build
PACKAGE_PATH := $(PWD)/package
GO_PATH := $(shell go env GOPATH)
GOLANGCI_LINT_BINARY := $(GO_PATH)/bin/golangci-lint
GOLANGCI_LINT_VERSION := v1.16.0
BINARY_EXT_linux :=
BINARY_EXT_darwin :=
BINARY_EXT_windows := .exe
DOCKER_IMAGE_RPM := alectolytic/rpmbuilder
DOCKER_IMAGE_DEB := appsody/debian-builder
CONTROLLER_BASE_URL := https://github.com/${GH_ORG}/controller/releases/download/0.2.1

#### Dynamic variables. These change depending on the target name.
# Gets the current os from the target name, e.g. the 'build-linux' target will result in os = 'linux'
# CAUTION: All targets that use these variables must have the OS after the first '-' in their name.
#          For example, these are all good: build-linux, tar-darwin, tar-darwin-new
os = $(word 2,$(subst -, ,$@))
build_name = $(COMMAND)-$(VERSION)-$(os)-amd64
build_binary = $(build_name)$(BINARY_EXT_$(os))
package_binary = $(COMMAND)$(BINARY_EXT_$(os))

.PHONY: all
all: lint test package ## Run lint, test, build, and package

.PHONY: get-cli
get-cli: ## get cli code from repo
	#wget https://github.com/appsody/appsody/archive/0.2.5.zip
	#unzip 0.2.5.zip

	# this way was working as of 7/24/19...
	# go env GOPATH
	# mkdir -p /home/travis/gopath/src/github.com/appsody
	# cd /home/travis/gopath/src/github.com/appsody && git clone https://github.com/tnixa/appsody.git
	# cd /home/travis/gopath/src/github.com/appsody/appsody && git checkout testsandbox
	# cd /home/travis/gopath/src/github.com/appsody/appsody && make install-controller
	# cd /home/travis/gopath/src/github.com/appsody/appsody/functest && go test

	# try new way with vendor path...
	
	go env GOPATH
	mkdir -p vendor/github.com/appsody
	cd vendor/github.com/appsody && git clone https://github.com/tnixa/appsody.git
	cd vendor/github.com/appsody/appsody && git checkout testsandbox
	cd vendor/github.com/appsody/appsody && make install-controller
	#unzip 0.2.5.zip -d vendor/github.com/appsody
	#mv vendor/github.com/appsody/appsody-0.2.5 vendor/github.com/appsody/appsody
	#$(EXPORTVAR) && cd vendor/github.com/appsody/appsody/functest && go test -v -count=1 -p=1 -run TestParser
	#go test -v -count=1 -p=1 ./vendor/github.com/appsody/appsody/functest -run TestParser

.PHONY: test
test: ## Run the all the automated tests
	$(GO_TEST_COMMAND) ./...  #pass in parameter for which stack to test
	
.PHONY: parser-test
parser-test: ## Run the all the automated tests
	#$(GO_TEST_COMMAND) ./...  #pass in parameter for which stack to test
	$(EXPORTVAR) && cd vendor/github.com/appsody/appsody/functest && $(GO_TEST_COMMAND) -run TestParser

.PHONY: run_simple-test
run_simple-test: ## Run the all the automated tests
	#$(GO_TEST_COMMAND) ./...  #pass in parameter for which stack to test
	$(EXPORTVAR) && cd vendor/github.com/appsody/appsody/functest && $(GO_TEST_COMMAND) -timeout 12h -run TestRunSimple

.PHONY: unittest
unittest: ## Run the automated unit tests
	$(GO_TEST_COMMAND) ./cmd

.PHONY: functest
functest: ## Run the automated functional tests
	$(GO_TEST_COMMAND) ./functest

.PHONY: lint
lint:  ## Run the static code analyzers
# Configure the linter here. Helpful commands include `golangci-lint linters` and `golangci-lint run -h`
# Set exclude-use-default to true if this becomes to noisy.
	echo "lint not implemented yet"


.PHONY: clean
clean: ## Removes existing build artifacts in order to get a fresh build
	rm -rf $(BUILD_PATH)
	rm -rf $(PACKAGE_PATH)
	rm -f $(GOLANGCI_LINT_BINARY)
	go clean

.PHONY: before-deploy
before-deploy: ## Scritp to run prior to deployment
	# will this work? ./ci/packageTemplates.sh .
	
.PHONY: tar-templates
tar-templates: ## Build the stack templates and package them in a .tar file
	echo "tar-templates not implemented yet"

.PHONY: build-index
brew-darwin: ## Build the index.yaml
	# brew script goes here
	cp -p $(BUILD_PATH)/$(build_binary) $(package_binary)
	homebrew-build/build-darwin.sh $(PACKAGE_PATH) $(package_binary) $(CONTROLLER_BASE_URL) $(VERSION)
	rm -f $(package_binary)	



.PHONY: build-docs
build-docs:
	# make docs md file
	mkdir my-project
	cd my-project && go run ../main.go docs --docFile $(BUILD_PATH)/cli-commands.md && sed -i.bak '/###### Auto generated by spf13/d' $(BUILD_PATH)/cli-commands.md && rm $(BUILD_PATH)/cli-commands.md.bak
	rm -rf my-project
.PHONY: deploy
deploy: ## Publishes the formula
	./deploy-build/deploy.sh
	./docs-build/deploy.sh




# Auto documented help from http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help: ## Prints this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
