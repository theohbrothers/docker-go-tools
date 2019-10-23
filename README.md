# docker-go-tools

A dockerized workflow that decouples the [go](https://golang.org/doc/install) runtime and tools from the developer's OS.

Enables completely dockerized Go development workflows:

- Bind-mounted `go` runtime files on Host
- Dockerized `go`
- Dockerized go debug tools (E.g. `dlv`, `gopls`, `bingo`)
- Standalone `<any go tool you like>`

With this, a developer machine becomes ephemeral, containing no development state. Also, a developer only needs to change one variable, to switch to a different `go` runtime version.

## How to

1. Install [`bindfs-1.13.10`](https://bindfs.org/) or higher. Required for Step 2.

2. Start a `go` daemon container, `bindfs`-mounting the go runtime files onto the host. Requires `sudo` privilege.

    ```sh
    make start-go-daemon
    ```

3. Build go and go tool wrappers and their docker images

    ```sh
    make
    ```

    E.g. A docker image named `gopls` is built. A wrapper `gopls` is generated in `./bin`

4. Add this repo's `./bin` to `$PATH`.

    `go` wrapper is now available

    ```sh
    $ which go
    /path/to/docker-go-tools/bin/go
    $ go
    ```

    Dockerized go tool wrappers should be used in the scope of a repo

    ```sh
    $ which dlv
    /path/to/docker-go-tools/bin/dlv
    # Ensure we are in the scope of a git repo
    $ cd /path/to/your/repo
    $ dlv
    ```

5. Get standalone (non-dockerized) go tools

    ```sh
    # Ensure we are not in the scope of a git repo
    cd ~
    $ go get github.com/golangbot/hello
    $ which hello
    /home/user/go/bin/hello
    $ hello
    Hello World
    ```

    You are now ready to start developing. `go`, go tool wrappers (`dlv`, `gopls`, `bingo` etc), and standalone go tools will work as intended. All without dependency on the Host system.

## Build more dockerized go tool wrappers

Let's build a dockerized `golint`

1. In `Makefile`:

    - Add `golint` to `ALL_BINS` in `Makefile`. E.g. `dlv gopls bingo golint`
    - Add `golint` package as a variable. E.g. `golint_PACKAGE := golang.org/x/lint/golint`

2. Run `make`.

## Remove the dockerized go tools wrappers

`make all-remove`

## How it works

### 1. Go runtime files

We create daemon `go` container, and `bindfs` its `GOROOT` (`/usr/local/go`) onto the Host at the same path (`/usr/local/go`). Read more [here](https://github.com/moby/moby/issues/26872#issuecomment-249416877).

This allows the user to access Go runtime / native files as though it were installed on the Host.
More importantly, it allows a local debugger (e.g. `dlv`) or go-to-definition tool (e.g. `godef`) to open the necessary Go native files.

### 2. `go` wrapper

When called outside of the folder of a git repository, the `GOPATH` is `$HOME/go`, and `GOCACHE` is `$HOME/.cache/go-build`, as defined in Makefile.

When called within the folder of a git repository, the `GOPATH` and `GOCACHE` are `/path/to/repo/.go` and `/path/to/repo/.go/.cache/go-build`, as defined in the Makefile. Your workspace environment *may* want to define these variables to override the wrapper's defaults just to be sure they are set correctly.

### 3. Go tools wrappers

These must be used in the folder of a git repository. The `GOPATH` and `GOCACHE` are `/path/to/repo/.go` and `/path/to/repo/.go/.cache/go-build`.

### 4. Standalone Go tools

The binaries will still reside in `GOPATH/bin` as defined in Makefile.

## FAQ

### Q: I see no files in `/usr/bin/go`?

You need to have at least `bindfs-1.13.10` or higher. More information [here](https://github.com/mpartel/bindfs/issues/66#issuecomment-428323548)

### Q: `bindfs` of the Go daemon container's `GOROOT` does not work on Docker for Windows or Docker for Mac?

Yes. The `bindfs` approach only works on Linux at the moment. This is because Docker for Windows/Mac both use a separate VM for the container space, and the host is unable to see the container's files. Read more details [here](https://github.com/moby/moby/issues/26872#issuecomment-249416877)
