# docker-go-tools

Dockerized go runtime and tools.

Eliminates the need for installation of Go on the dev system.
Enables completely dockerized Go development workflows:
  - Bind-mounted `go` runtime files on Host
  - Dockerized `go`
  - Dockerized `dlv`
  - Dockerized `gopls`
  - Dockerized `bingo`

## How to use

1. Install [`bindfs-1.13.10`](https://bindfs.org/) or higher

2. Start a `go` daemon container, bind-mounting the go runtime files onto the host

    ```
    make start-go-daemon
    ```

3. Build go tool wrappers and their docker images

    ```sh
    make
    ```

    E.g. A docker image named `gopls` is built. A wrapper `gopls` is generated in `.bin/`

4. Add this repo's `./bin` to `$PATH`

5. Use the binaries

    ```sh
    go ...
    ```

    Tools should be used in the scope of a repo

    ```sh
    dlv
    gopls
    bingo
    ```

## Build a custom go tool

Let's build `golint``

1. In `Makefile`:
  - Add `golint` to `ALL_BINS` in `Makefile`. E.g. `dlv gopls bingo golint`
  - Add `golint` package as a variable. E.g. `golint_PACKAGE := golang.org/x/lint/golint`

2. Run `make build-golint`.

## Remove the dockerized go tools

`make all-remove`

## How it works

### Go runtime files

We create daemon `go` container, and `bindfs` its `GOROOT` (`/usr/local/go`) onto the Host at the same path (`/usr/local/go`).

This allows the user to access Go runtime files as though it were installed on the Host.

### Go

For `go`, the current user should have `rwx` access to `GOPATH` and `GOCACHE` as defined in `Makefile` before the wrapper will run.

### Go tools

For go tools( e.g. `dlv`), the `$PWD` (current working directory) must contain `PWD_GOPATH` and `PWD_GOCACHE` as defined in the `Makefile` before the wrapper will run.

## Todo

Make binaries that dont require `GOPATH=$PWD/.go` and `GOCACHE=$PWD/.cache/go-build` in the `$PWD`
