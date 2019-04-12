ARG GO_IMAGE
FROM $GO_IMAGE

ARG PACKAGE
RUN echo "PACKAGE: $PACKAGE" \
    && go get -u -v "$PACKAGE" \
    && rm -rf "$GOCACHE" \
    && rm -rf "$GOPATH/src/*" \
    && rm -rf "$GOPATH/pkg/*"
