#!/bin/bash

sudo chsh "$(id -un)" --shell "/usr/bin/zsh"
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply imwithye
