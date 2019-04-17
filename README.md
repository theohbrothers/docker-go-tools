# docker-go-tools

Dockerized go runtime and tools.

Eliminates the need for installation of [Go](https://golang.org/doc/install) on a developer's machine.
Enables completely dockerized Go development workflows:
  - Bind-mounted `go` runtime files on Host
  - Dockerized `go`
  - Dockerized go debug tools (E.g. `dlv`, `gopls`, `bingo`)
  - Standalone `<any go tool you like>`

## How to use

1. Install [`bindfs-1.13.10`](https://bindfs.org/) or higher. Required for Step 2.

2. Start a `go` daemon container, `bindfs`-mounting the go runtime files onto the host. Requires `sudo` privilege.

    ```
    $ make start-go-daemon
    ```

3. Build go and go tool wrappers and their docker images

    ```sh
    $ make
    ```

    E.g. A docker image named `gopls` is built. A wrapper `gopls` is generated in `.bin/`

4. Add this repo's `./bin` to `$PATH`.

    `go` is now available

    ```sh
    $ which go
    /path/to/docker-go-tools/bin/go
    $ go
    ```

    go tools should be used in the scope of a repo

    ```sh
    $ which go
    /path/to/docker-go-tools/bin/dlv
    $ cd /path/to/your/repo
    $ dlv
    $ gopls
    $ bingo
    ```

5. Get standalone (non-dockerized) go tools

    ```sh
    $ go get github.com/golangbot/hello
    $ which hello
    /home/user/go/bin/hello
    $ hello
    Hello World
    ```

You are now ready to start developing. `go`, go tool wrappers (`dlv`, `gopls`, `bingo` etc), and standalone go tools will work as intended. All without cluttering the Host system.

## Build more dockerized go wrappers

Let's build a dockerized `golint`

1. In `Makefile`:
  - Add `golint` to `ALL_BINS` in `Makefile`. E.g. `dlv gopls bingo golint`
  - Add `golint` package as a variable. E.g. `golint_PACKAGE := golang.org/x/lint/golint`

2. Run `make`.

## Remove the dockerized go tools

`make all-remove`

## How it works

### 1. Go runtime files

We create daemon `go` container, and `bindfs` its `GOROOT` (`/usr/local/go`) onto the Host at the same path (`/usr/local/go`). Read more [here](https://github.com/moby/moby/issues/26872#issuecomment-249416877).

This allows the user to access Go runtime / native files as though it were installed on the Host.
More importantly, it allows a local debugger (e.g. `dlv`) or go-to-definition tool (e.g. `godef`) to open the necessary Go native files.

### 2. `go`

For `go`, the `GOPATH` and `GOCACHE` as defined in Makefile are used.

### 3. Dockerized Go tools

For dockerized go tools( e.g. `dlv`),  a repo `GOPATH` and `GOCACHE` are `/repo/.go` and `/repo/.cache/go-build/`. If these paths do not exist, the default `GOPATH` and `GOCACHE` as defined in Makefile are used.

### 4. Standalone Go tools

The binaries will reside in `GOPATH/bin` as defined in Makefile.

## FAQ

### Q: I see no files in `/usr/bin/go`?

You need to have at least `bindfs-1.13.10` or higher. More information [here](https://github.com/mpartel/bindfs/issues/66#issuecomment-428323548)

### Q: `bindfs` of the Go daemon container's `GOROOT` does not work on Docker for Windows or Docker for Mac?

Yes. The `bindfs` approach only works on Linux at the moment. This is because Docker for Windows/Mac both use a separate VM for the container space, and the host is unable to see the container's files. Read more details [here](https://github.com/moby/moby/issues/26872#issuecomment-249416877)

## Todo

Make go tools that dont require `PWD_GOPATH` and `PWD_GOCACHE` in the `$PWD`
