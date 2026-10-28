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

# Cursor shape: block in normal mode, beam in insert mode
autoload -Uz add-zle-hook-widget add-zsh-hook
_vi_cursor() {
  if [[ $KEYMAP == vicmd ]]; then printf '\e[2 q'; else printf '\e[6 q'; fi
}
add-zle-hook-widget zle-keymap-select _vi_cursor
add-zle-hook-widget zle-line-init _vi_cursor
_vi_cursor_reset() { printf '\e[6 q'; }   # beam for programs launched from the prompt
add-zsh-hook preexec _vi_cursor_reset

# Powerlevel10k prompt (installed via Homebrew). Run `p10k configure` to restyle.
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

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

# Machine-specific settings and secrets (not tracked in ~/dotconfig)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
