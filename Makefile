GO_IMAGE_NAMESPACE = golang
GO_IMAGE_TAG = 1.12
GO_IMAGE = $(GO_IMAGE_NAMESPACE):$(GO_IMAGE_TAG)

ALL_BINS = dlv gopls
dlv_PACKAGE = github.com/go-delve/delve/cmd/dlv
gopls_PACKAGE = github.com/go-delve/delve/cmd/gopls
bingo_PACKAGE = github.com/saibing/bingo

all-build: $(addprefix build-, $(ALL_BINS))
all-list: $(addprefix list-, $(ALL_BINS))
all-remove: $(addprefix remove-, $(ALL_BINS))

build-%: ./build/Dockerfile
	$(eval BIN=$*)
	@BIN=$(BIN) BIN_WRAPPER=./bin/$$BIN IMAGE_ID=$$(docker images -q --filter "reference=$$BIN") \
		&& [ -n "$$IMAGE_ID" ] \
		&& echo "$$BIN image already exists" \
		|| ( echo "$$BIN image does not exist. Will build $$BIN image" \
			&& docker build -t "$$BIN" --build-arg "GO_IMAGE=$(GO_IMAGE)" --build-arg "PACKAGE=$($(BIN)_PACKAGE)" -f ./build/Dockerfile ./build \
		   ) \
		&& echo "Creating bin wrapper in $$BIN_WRAPPER" \
		&& touch $$BIN_WRAPPER \
		&& chmod +x $$BIN_WRAPPER \
		&& echo "#!/bin/sh" > $$BIN_WRAPPER \
		&& echo "docker run --rm $$BIN $$BIN" '"$$@"' >> $$BIN_WRAPPER

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
