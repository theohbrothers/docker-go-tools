# VSCode Go intellisense

## Build the dockerized tools and use them

1. Build the dockerized go tools

    ```sh
    make
    ```

2. Add this repo's `./bin` to `$PATH`

3. Use the binaries!

    ```sh
    gopls
    ```

## Remove the dockerized go tools

`make all-remove`

