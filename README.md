# docker-go-tools

Dockerized go tools.

Eliminates the need for installation of Go on the dev system.
Enables completely dockerized Go development workflows:
  - Dockerized `go`
  - Dockerized `dlv`
  - Dockerized `gopls`
  - Dockerized `bingo`


## Build the dockerized tools and use them

1. Build the go tool wrappers and docker images

    ```sh
    make
    ```

  E.g. A docker image named `gopls` is built. A wrapper `gopls` is generated in `.bin/`

2. Add this repo's `./bin` to `$PATH`

3. Use the binaries in the scope of your repo.

    ```sh
    dlv
    gopls
    bingo
    ```
## Remove the dockerized go tools

`make all-remove`

## Notes

For `go`, the current user must have created and have access to `GOPATH` and `GOCACHE` as defined in `Makefile` before the wrapper will run.

For go tools( e.g. `dlv`), the `$PWD` (current working directory) must contain `PWD_GOPATH` and `PWD_GOCACHE` as defined in the `Makefile` before the wrapper will run.

## Todo

Make binaries that dont require `GOPATH=$PWD/.go` and `GOCACHE=$PWD/.cache/go-build` in the `$PWD`
