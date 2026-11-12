# Powerlevel10k instant prompt — keep near the top of ~/.zshrc.
# Anything that needs console input (passwords, [y/n] prompts) goes above this block.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Ensure ~/.local/bin is on PATH (Claude Code and other user-local tools live here)
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# --- Vi mode for the command line ---
bindkey -v
export KEYTIMEOUT=1   # switch to normal mode right after Esc (10ms)

# Keep a few emacs-style keys in insert mode
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^?' backward-delete-char   # backspace past where insert began
bindkey -M viins '^H' backward-delete-char
# Opt+Left/Right (Ghostty sends Esc b / Esc f) move by word instead of
# being read as Esc (normal mode) then b / f
bindkey -M viins '^[b' backward-word
bindkey -M viins '^[f' forward-word

# Up/Down (and k/j in normal mode) search history by what's already typed
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey -M viins '^[[A' up-line-or-beginning-search
bindkey -M viins '^[[B' down-line-or-beginning-search
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

# In normal mode, `v` opens the current command in $EDITOR
export EDITOR=nvim
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# --- History & fzf fuzzy finder ---
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# Set up fzf (Ctrl+R for history search, Ctrl+T for files, Alt+C for dirs)
if (( $+commands[fzf] )); then
  if fzf --zsh >/dev/null 2>&1; then
    eval "$(fzf --zsh)"
  else
    for _fzf_dir in \
      /opt/homebrew/opt/fzf/shell \
      /usr/local/opt/fzf/shell \
      ~/.fzf/shell \
      /usr/share/doc/fzf/examples
    do
      if [[ -d $_fzf_dir ]]; then
        [[ -f $_fzf_dir/key-bindings.zsh ]] && source "$_fzf_dir/key-bindings.zsh"
        [[ -f $_fzf_dir/completion.zsh ]] && source "$_fzf_dir/completion.zsh"
        break
      fi
    done
    unset _fzf_dir
  fi
fi

# v [file]   open Neovim (vim still runs plain Vim with ~/.vimrc)
alias v='nvim'

# Cursor shape: block in normal mode, beam in insert mode
autoload -Uz add-zle-hook-widget add-zsh-hook
_vi_cursor() {
  if [[ $KEYMAP == vicmd ]]; then printf '\e[2 q'; else printf '\e[6 q'; fi
}
add-zle-hook-widget zle-keymap-select _vi_cursor
add-zle-hook-widget zle-line-init _vi_cursor
_vi_cursor_reset() { printf '\e[6 q'; }   # beam for programs launched from the prompt
add-zsh-hook preexec _vi_cursor_reset

# Powerlevel10k prompt: Homebrew on macOS, a git clone in ~ or a distro package on
# Linux. Skipped quietly if not installed. Run `p10k configure` to restyle.
for _p10k in \
  /opt/homebrew/share/powerlevel10k \
  /home/linuxbrew/.linuxbrew/share/powerlevel10k \
  ~/powerlevel10k \
  /usr/share/zsh-theme-powerlevel10k
do
  if [[ -r $_p10k/powerlevel10k.zsh-theme ]]; then
    source $_p10k/powerlevel10k.zsh-theme
    [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
    break
  fi
done
unset _p10k

# --- tmux shortcuts ---
# t          attach to the most recent session (or create "main" if none exist)
# t <name>   attach to <name>, creating it if needed; inside tmux, switch to it
t() {
  if [[ -z $1 ]]; then
    tmux attach 2>/dev/null || tmux new-session -s main
  elif [[ -n $TMUX ]]; then
    tmux has-session -t "=$1" 2>/dev/null || tmux new-session -d -s "$1"
    tmux switch-client -t "=$1"
  else
    tmux new-session -A -s "$1"
  fi
}
alias tl='tmux ls'
# tk         inside tmux: kill the current session (asks first)
# tk <name>  kill session <name>
tk() {
  if [[ -n $1 ]]; then
    tmux kill-session -t "=$1"
  elif [[ -n $TMUX ]]; then
    local s=$(tmux display-message -p '#S')
    if read -q "?Kill session $s? (y/n) "; then echo; tmux kill-session -t "=$s"; else echo; fi
  else
    echo 'usage: tk <session>   (sessions: tl)' >&2
    return 1
  fi
}

# Machine-specific settings and secrets (not tracked in ~/repo/dotconfig)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
