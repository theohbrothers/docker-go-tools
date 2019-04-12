# docker-go-tools

Dockerized go binaries.

Enables completely dockerized Go development workflows:
  - Dockerized `dlv`
  - Dockerized `gopls`

## Build the dockerized tools and use them

1. Build the dockerized go tools. E.g. for `gopls`, and image named `gopls` is built.

    ```sh
    make
    ```

2. Add this repo's `./bin` to `$PATH`

3. Use the binaries in the scope of your repo. Every repo must contain `GOPATH=$PWD/.go` and `GOCACHE=$PWD/.cache/go-build`, or the binary wrappers wont run.

    ```sh
    dlv
    gopls
    bingo
    ```

## Remove the dockerized go tools

`make all-remove`

## Todo

Make binaries that dont require `GOPATH=$PWD/.go` and `GOCACHE=$PWD/.cache/go-build` in the `$PWD`
