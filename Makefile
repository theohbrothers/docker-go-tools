##########################################################
#
# A Makefile to create dockerized go tools
#
##########################################################

# Define go's GOPATH and GOCACHE. Do not edit GOROOT!
GOPATH := $$HOME/.cache/go-build
GOCACHE := $$HOME/go
GOROOT := /usr/local/go

# Define go tool's GOPATH and GOCACHE here. Should not need tweaking
PWD_GOPATH := $$PWD/.go
PWD_GOCACHE := $$PWD/.cache/go-build

# Define the go image
BUILD_IMAGE_NAMESPACE := golang
BUILD_IMAGE_TAG := 1.12
BUILD_IMAGE := $(BUILD_IMAGE_NAMESPACE):$(BUILD_IMAGE_TAG)

# Define the go tools to build
ALL_BINS := dlv gopls bingo

# Define the go tools package, in format <BIN>_PACKAGE
dlv_PACKAGE := github.com/go-delve/delve/cmd/dlv
gopls_PACKAGE := golang.org/x/tools/cmd/gopls
bingo_PACKAGE := github.com/saibing/bingo

# Define any go tools additional docker run options
dlv_DOCKER_RUN_OPTIONS := --security-opt seccomp:unconfined

##########################################################

all-build: $(addprefix build-, $(ALL_BINS)) build-go
all-list: $(addprefix list-, $(ALL_BINS))
all-remove: $(addprefix remove-, $(ALL_BINS))

# Creates a go binary wrapper (in ./bin) that runs the docker go image
build-go:
	$(eval BIN=go)
	@mkdir -p $(GOPATH) $(GOCACHE)
	$(MAKE) wrapper BIN=go

# Builds a go tool docker image tagged as $BIN, and creates the tool wrapper (in ./bin)
build-%: ./build/Dockerfile
	$(eval BIN=$*)
	@IMAGE_ID=$$(docker images -q --filter "reference=$(BIN)") \
		&& [ -n "$$IMAGE_ID" ] \
		&& echo "$(BIN) image already exists" \
		|| ( echo "$(BIN) image does not exist. Will build $(BIN) image" \
			&& docker build -t "$(BIN)" --build-arg "BUILD_IMAGE=$(BUILD_IMAGE)" --build-arg "BIN=$(BIN)" --build-arg "PACKAGE=$($(BIN)_PACKAGE)" -f ./build/Dockerfile ./build \
		   ) \
		&& $(MAKE) wrapper BIN=$(BIN)

# Creates a binary wrapper (in ./bin) that runs the tool's docker image
wrapper:
	$(eval BIN_WRAPPER=./bin/$(BIN))
	@echo "Creating bin wrapper in $(BIN_WRAPPER)"
	@touch $(BIN_WRAPPER) && chmod +x $(BIN_WRAPPER)
	@echo '#!/bin/sh' > $(BIN_WRAPPER)
ifeq ($(BIN),go)
	@echo '[ ! -d $(GOPATH) ] && echo "Host GOPATH $(GOPATH) not found" >&2 && exit 1' >> $(BIN_WRAPPER)
	@echo '[ ! -d $(GOCACHE) ] && echo "Host GOCACHE $(GOCACHE) not found" >&2 && exit 1' >> $(BIN_WRAPPER)
	@echo 'docker run --rm -i -u $$(id -u):$$(id -g) --network=host $($(BIN)_DOCKER_RUN_OPTIONS) -e GOPATH=$(GOPATH) -e GOCACHE=$(GOCACHE) -v $$PWD:/$$PWD -w $$PWD -v $(GOPATH):/go -v $(GOCACHE):/.cache/go-build $(BUILD_IMAGE) go "$$@"' >> $(BIN_WRAPPER)
else
	@echo '[ ! -d $(PWD_GOPATH) ] && echo "PWD_GOPATH $(PWD_GOPATH) not found" >&2 && exit 1' >> $(BIN_WRAPPER)
	@echo '[ ! -d $(PWD_GOCACHE) ] && echo "PWD_GOCACHE $(PWD_GOCACHE) not found" >&2 && exit 1' >> $(BIN_WRAPPER)
	@echo 'docker run --rm -i -u $$(id -u):$$(id -g) --network=host $($(BIN)_DOCKER_RUN_OPTIONS) -e GOPATH=$(PWD_GOPATH) -e GOCACHE=$(PWD_GOCACHE) -v $$PWD:$$PWD -w $$PWD -v $(PWD_GOPATH):/go -v $(PWD_GOCACHE):/.cache/go-build' $(BIN) $(BIN) '"$$@"' >> $(BIN_WRAPPER)
endif

# List a go tool's docker image
list-%:
	$(eval BIN=$*)
	@echo "Looking for image of reference $(BIN)" >&2 \
		&& docker images -q --filter "reference=$(BIN)"

# Removes a go tool's docker image, and its wrapper from ./bin
remove-%:
	$(eval BIN=$*)
	@BIN_WRAPPER=./bin/$(BIN) \
		&& echo "Removing $$BIN image" \
		&& docker rmi "$(BIN)" \
		&& echo "Removing bin wrapper in $(BIN_WRAPPER)" \
		&& rm -rf $(BIN_WRAPPER)

# Starts a infinity Go container, and bindfs mount the container's GOROOT (/proc/<PID>/root/usr/local/go) onto the Host (/usr/local/go)
# Note: Requires bindfs-1.13.10 and higher. See: https://github.com/mpartel/bindfs/issues/66#issuecomment-428323548
start-go-daemon: $(build-go)
	@NAME=$(BUILD_IMAGE_NAMESPACE$)$(BUILD_IMAGE_TAG) ID=$$( docker ps -q --filter name=$$NAME )	\
		&& echo "Starting Go container" \
		&& [ -z $$ID ] \
		&& ID=$$( docker run -d --name $$NAME --restart always $(BUILD_IMAGE) sh -c 'sleep 999999999d' ) \
		&& echo "$$ID" \
		|| echo "$$ID" \
	&& echo "Mounting container GOROOT on host $(GOROOT)" \
		&& mount | grep $(GOROOT) && echo "container GOROOT $(GOROOT) already mounted on host $(GOROOT)" \
		|| ( \
			PID=$$( docker inspect --format {{.State.Pid}} $$ID ) \
			&& [ -n $$PID ] \
			&& echo "Command: sudo bindfs --map=root/$$USER /proc/$(PID)/root$(GOROOT) $(GOROOT)" \
			&& sudo mkdir -p $(GOROOT) \
			&& sudo bindfs --map=root/$$USER /proc/$$PID/root$(GOROOT) $(GOROOT) \
		   )
# Stops a infinity Go container, and unmounts the bindfs mount (/usr/local/go) on the Host
stop-go-daemon:
	@NAME=$(BUILD_IMAGE_NAMESPACE$)$(BUILD_IMAGE_TAG) \
		&& echo "Stopping Go container" \
		&& docker rm -f $$NAME 2>/dev/null \
		|| echo "Go container not running"
	@echo "Unmounting host $(GOROOT)" \
		&& sudo umount $(GOROOT) || true

# Show some make variables
env:
	echo "GOROOT: $(GOROOT)"
	echo "GOPATH: $(GOPATH)"
	echo "GOCACHE: $(GOCACHE)"
