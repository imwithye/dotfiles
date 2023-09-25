#!/bin/bash

sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin init --apply imwithye
cd $HOME/.local/share/chezmoi
git remote set-url origin git@github.com:imwithye/dotfiles.git

