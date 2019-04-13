# docker-go-tools

Dockerized go runtime and tools.

Eliminates the need for installation of [Go](https://golang.org/doc/install) on a developer's machine.
Enables completely dockerized Go development workflows:
  - Bind-mounted `go` runtime files on Host
  - Dockerized `go`
  - Dockerized `dlv`
  - Dockerized `gopls`
  - Dockerized `bingo`
  - Dockerized `<any tool you like>`

## How to use

1. Install [`bindfs-1.13.10`](https://bindfs.org/) or higher. Required for Step 2.

2. Start a `go` daemon container, `bindfs`-mounting the go runtime files onto the host. Requires `sudo` privilege.

    ```
    make start-go-daemon
    ```

3. Build go tool wrappers and their docker images

    ```sh
    make
    ```

    E.g. A docker image named `gopls` is built. A wrapper `gopls` is generated in `.bin/`

4. Add this repo's `./bin` to `$PATH`

5. Binaries are now available

    ```sh
    go ...
    ```

    Tools should be used in the scope of a repo

    ```sh
    dlv
    gopls
    bingo
    ```

You are now ready to start developing. `dlv` and other debugging tools will work as intended. All without cluttering the Host system.

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

This allows the user to access Go runtime / native files as though it were installed on the Host.
More importantly, it allows a local debugger (e.g. `dlv`) or go-to-definition tool (e.g. `godef`) to open the necessary Go native files.

### Go

For `go`, the current user should have `rwx` access to `GOPATH` and `GOCACHE` as defined in `Makefile` before the wrapper will run.

### Go tools

For go tools( e.g. `dlv`), the `$PWD` (current working directory) must contain `PWD_GOPATH` and `PWD_GOCACHE` as defined in the `Makefile` before the wrapper will run.

## Todo

Make binaries that dont require `GOPATH=$PWD/.go` and `GOCACHE=$PWD/.cache/go-build` in the `$PWD`
