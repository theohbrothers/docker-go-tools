##########################################################
#
# A Makefile to create dockerized go tools
#
##########################################################

##########################################################

# Define GOPATH and GOCACHE here. Should not need tweaking
GOROOT := /usr/local/go
GOPATH := $$PWD/.go
GOCACHE := $$PWD/.cache/go-build

# Define the go image
BUILD_IMAGE_NAMESPACE := golang
BUILD_IMAGE_TAG := 1.12
BUILD_IMAGE := $(BUILD_IMAGE_NAMESPACE):$(BUILD_IMAGE_TAG)

# Define the go tools to build here
ALL_BINS := dlv gopls bingo
dlv_PACKAGE := github.com/go-delve/delve/cmd/dlv
gopls_PACKAGE := golang.org/x/tools/cmd/gopls
bingo_PACKAGE := github.com/saibing/bingo

# Docker run port, extracted from params
dlv_PORT := PORT=$$( echo "$$@" | sed "s@.*--listen=[^:]*:\\([0-9]\+\\).*@\\1@" )
# Docker CMD params find and replacement
dlv_PARAMS_REPLACEMENT := set -- $$( echo "$$@" | sed "s@--listen=127.0.0.1@--listen=@" )
# Docker run security-opt. Required for some tools, e.g. dlv
dlv_DOCKER_RUN_OPTIONS := --security-opt seccomp:unconfined -p $$PORT:$$PORT

##########################################################

all-build: $(addprefix build-, $(ALL_BINS))
all-list: $(addprefix list-, $(ALL_BINS))
all-remove: $(addprefix remove-, $(ALL_BINS))

build-%: ./build/Dockerfile
	$(eval BIN=$*)
	@BIN=$(BIN) BIN_WRAPPER=./bin/$$BIN \
		IMAGE_ID=$$(docker images -q --filter "reference=$$BIN") \
		&& [ -n "$$IMAGE_ID" ] \
		&& echo "$$BIN image already exists" \
		|| ( echo "$$BIN image does not exist. Will build $$BIN image" \
			&& docker build -t "$$BIN" --build-arg "BUILD_IMAGE=$(BUILD_IMAGE)" --build-arg "BIN=$(BIN)" --build-arg "PACKAGE=$($(BIN)_PACKAGE)" -f ./build/Dockerfile ./build \
		   ) \
		&& echo "Creating bin wrapper in $$BIN_WRAPPER" \
		&& touch $$BIN_WRAPPER \
		&& chmod +x $$BIN_WRAPPER \
		&& echo "#!/bin/sh" > $$BIN_WRAPPER \
		&& echo '[ ! -d $(GOPATH) ] && echo "GOPATH $(GOPATH) not found" >&2 && exit 1' >> $$BIN_WRAPPER \
		&& echo '[ ! -d $(GOCACHE) ] && echo "GOPATH $(GOCACHE) not found" >&2 && exit 1' >> $$BIN_WRAPPER \
		&& echo '$($(BIN)_PORT)' >> $$BIN_WRAPPER \
		&& echo '$($(BIN)_PARAMS_REPLACEMENT)' >> $$BIN_WRAPPER \
		&& echo 'docker run -i -u $$(id -u):$$(id -g) --rm $($(BIN)_DOCKER_RUN_OPTIONS) -e GOPATH=$(GOPATH) -e GOCACHE=$(GOCACHE) -v $$PWD:$$PWD -w $$PWD -v $(GOPATH):/go -v $(GOCACHE):/.cache/go-build' $$BIN $$BIN '"$$@"' >> $$BIN_WRAPPER

list-%:
	$(eval BIN=$*)
	@echo "Looking for image of reference $(BIN)" >&2 \
		&& docker images -q --filter "reference=$(BIN)"

remove-%:
	$(eval BIN=$*)
	@BIN=$(BIN) BIN_WRAPPER=./bin/$$BIN \
		&& echo "Removing $$BIN image" \
		&& docker rmi "$$BIN" \
		&& echo "Removing bin wrapper in $$BIN_WRAPPER" \
		&& rm -rf $$BIN_WRAPPER

env:
	echo "GOROOT: $(GOROOT)"
	echo "GOPATH: $(GOPATH)"
	echo "GOCACHE: $(GOCACHE)"

# Starts a infinity Go container, and bindfs mount the container's GOROOT onto the host
start-mount:
	@NAME=$(BUILD_IMAGE_NAMESPACE$)$(BUILD_IMAGE_TAG) ID=$$( docker ps -q --filter name=$$NAME )	\
		&& echo "Starting Go container" \
		&& [ -z $$ID ] \
		&& ID=$$( docker run -d --name $$NAME --restart always $(BUILD_IMAGE) bash -c 'sleep infinity' ) \
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
# Stops a infinity Go container, and unmounts the bindfs mount on the host
stop-mount:
	@NAME=$(BUILD_IMAGE_NAMESPACE$)$(BUILD_IMAGE_TAG) \
		&& echo "Stopping Go container" \
		&& docker rm -f $$NAME 2>/dev/null \
		|| echo "Go container not running"
	@echo "Unmounting host $(GOROOT)" \
		&& sudo umount $(GOROOT) || true
