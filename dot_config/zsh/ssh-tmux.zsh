# Auto-attach tmux on ssh/mosh login.
#
#   SSH_TMUX_AUTO_ENABLED=true    enable (set it on the *remote* host)
#   SSH_TMUX_SESSION_NAME=<name>  session name, defaults to "ssh-session"
#
# Set those in ~/.zshrc.local, which .zshrc sources just before this file.
# Detaching tmux ends the login shell, which drops the ssh/mosh connection.

_ssh_tmux_autostart() {
  [[ "${SSH_TMUX_AUTO_ENABLED:l}" == (true|1|yes|on) ]] || return
  [[ -o interactive ]] || return
  [[ -z "$TMUX" ]] || return        # already inside tmux
  [[ -t 0 && -t 1 ]] || return      # need a real tty
  [[ "$TERM" != (dumb|unknown) ]] || return

  # mosh does not always export SSH_*, so fall back to walking the process tree
  local remote=0
  if [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    remote=1
  else
    local pid=$PPID name i
    for i in {1..12}; do
      [[ $pid -gt 1 ]] || break
      name=${${(f)"$(ps -o comm= -p $pid 2>/dev/null)"}:t}
      [[ -n "$name" ]] || break
      [[ "$name" == (sshd|sshd-session|mosh-server) ]] && { remote=1; break }
      pid=${${(f)"$(ps -o ppid= -p $pid 2>/dev/null)"}// /}
    done
  fi
  (( remote )) || return

  local tmux_bin
  for tmux_bin in \
    $commands[tmux] \
    /opt/homebrew/bin/tmux \
    /home/linuxbrew/.linuxbrew/bin/tmux \
    /usr/local/bin/tmux \
    /usr/bin/tmux; do
    [[ -x "$tmux_bin" ]] && break
  done
  if [[ ! -x "$tmux_bin" ]]; then
    print -u2 "SSH_TMUX_AUTO_ENABLED is set but tmux is not installed on $(hostname -s)."
    print -u2 "Install it (brew install tmux / apt install tmux / dnf install tmux) or unset the variable."
    return
  fi

  # -A attaches to the session if it exists, creates it otherwise.
  # Add -D if you want reconnecting to kick any stale client off the session.
  "$tmux_bin" new-session -A -s "${SSH_TMUX_SESSION_NAME:-ssh-session}" && exit
  # tmux failed to start: fall through to a plain shell rather than disconnect
}

_ssh_tmux_autostart
unfunction _ssh_tmux_autostart
