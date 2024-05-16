#! /bin/bash

curl https://sh.rustup.rs -sSf | sh
exec zsh
cargo install --locked zellij
