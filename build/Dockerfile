ARG BUILD_IMAGE
FROM $BUILD_IMAGE

ARG BIN
ARG PACKAGE

RUN echo "PACKAGE: $PACKAGE" \
    && go get -u -v "$PACKAGE" \
    && mv /go/bin/$BIN /usr/local/bin \
    && rm -rf "$GOCACHE" \
    && rm -rf "$GOPATH/src/*" \
    && rm -rf "$GOPATH/pkg/*"

