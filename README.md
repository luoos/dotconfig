# dotconfig

My macOS terminal setup: Ghostty, tmux, zsh, Neovim and Vim, kept in one repo so
every change has history and a new Mac can be set up in a few commands.

The real files live here; [GNU Stow](https://www.gnu.org/software/stow/) puts
symlinks to them in `~`, so editing `~/.tmux.conf` edits the file in this repo.

## What's included

Each top-level folder is a Stow *package*. Inside it, files sit at the same path
they'd have relative to `~`.

| Package   | Links to                        | What it is |
|-----------|---------------------------------|------------|
| `ghostty` | `~/.config/ghostty/`            | Ghostty terminal: Breadog light theme, font size, split keys |
| `tmux`    | `~/.tmux.conf`                  | tmux: mouse, vi copy mode to the macOS clipboard, `\|` / `-` splits, Ctrl+h/j/k/l across tmux and Neovim, PageUp to scroll |
| `zsh`     | `~/.zshrc`, `~/.p10k.zsh`       | zsh with vi mode, Powerlevel10k prompt, `t` shortcut for tmux sessions |
| `nvim`    | `~/.config/nvim/`               | Neovim 0.12+, plugins via the built-in `vim.pack` (versions pinned in `nvim-pack-lock.json`) |
| `vim`     | `~/.vimrc`                      | Plain Vim, sharing Ghostty's 16-color palette |

Not included on purpose: SSH keys, shell history, git credentials and anything
else secret. **This repo is public.** Put machine-specific settings and secrets
in `~/.zshrc.local`, which `.zshrc` loads if it exists and which is never
tracked.

## Setup on a new Mac

1. Install the tools:

   ```bash
   brew install stow tmux neovim powerlevel10k
   brew install --cask ghostty
   ```

2. Clone this repo into your home folder (the location matters: `.stowrc`
   links into `~`):

   ```bash
   git clone https://github.com/luoos/dotconfig.git ~/dotconfig
   ```

3. Create the links:

   ```bash
   cd ~/dotconfig && stow ghostty tmux zsh nvim vim
   ```

   If a config already exists at a target path (for example a default
   `~/.zshrc`), Stow stops and lists the conflicts without changing anything.
   Move those files aside and run it again, or run `stow --adopt <package>` to
   pull the existing file into the repo and then `git diff` to decide what to
   keep.

4. Open a new terminal. Neovim installs its plugins on first launch.

## Day-to-day

- **Edit a config:** edit it where it normally lives (`~/.tmux.conf`, `nvim`'s
  `init.lua`, …) or in this repo. It's the same file. Then commit here.
- **Reload:** tmux `prefix r`, zsh `source ~/.zshrc`, Ghostty `Cmd+Shift+,`,
  Neovim restart.
- **Update Neovim plugins:** `:lua vim.pack.update()` in Neovim, then commit the
  changed `nvim-pack-lock.json`.
- **Add another app's config:** create a package that mirrors the path under
  `~`, move the file in, and stow it. For example, for `~/.config/zed/`:

  ```bash
  mkdir -p ~/dotconfig/zed/.config
  mv ~/.config/zed ~/dotconfig/zed/.config/
  cd ~/dotconfig && stow zed
  ```

- **Remove the links for a package:** `stow -D <package>`. The files stay in
  the repo.
- **Re-check links after moving things:** `stow -R <package>`.

## History

Before October 2026 this repo held only an older Neovim config (lazy.nvim,
Telescope, Neo-tree, nvim-cmp, Catppuccin). It was replaced by the current
`vim.pack` setup; the old version is in the git history (commit `3e0cb64`).
