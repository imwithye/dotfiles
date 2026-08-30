# shared.sh — helpers shared by the scripts in this directory
#
# Source it from a script in the same directory:
#     . "$(dirname "$0")/shared.sh"
# Sets no shell options; each script decides its own `set -eu`.
#
#   note/warn/die/step   tagged, coloured log lines on stderr
#   usage                prints the script's header comment block
#   ask/prompt           yes-no and free-text questions
#   poll                 retry a command every 5 seconds

# Colour only when stderr is a terminal, so pipes and logs stay plain.
if [ -t 2 ]; then B='\033[34m'; Y='\033[33m'; R='\033[31m'; D='\033[1m'; Z='\033[0m'
else B=; Y=; R=; D=; Z=; fi
# INFO is padded so every tag is 7 columns and the messages line up.
note() { printf "${B}[INFO ]${Z} %s\n" "$*" >&2; }
warn() { printf "${Y}[WARN ]${Z} %s\n" "$*" >&2; }
die() { printf "${R}[ERROR]${Z} %s\n" "$*" >&2; exit 1; }
# Steps are separated by a blank line; the first one sits flush under the prompt.
step() { printf "${_stepped:+\n}${D}==> %s${Z}\n" "$*" >&2; _stepped=1; }

# Prints the calling script's header block, however long it grows, minus its
# comment markers. $0 is the script even though this is defined in the lib.
usage() { awk 'NR > 2 { if (!/^#/) exit; sub(/^# ?/, ""); print }' "$0"; }

# ask "question" y|n -- default is taken on a bare Enter.
ask() {
  [ "$2" = y ] && _hint="[Y/n]" || _hint="[y/N]"
  while :; do
    printf "%s %s " "$1" "$_hint" >&2
    read -r ANSWER || die "no answer on stdin"
    case "${ANSWER:-$2}" in
      y|Y|yes|YES) return 0 ;;
      n|N|no|NO) return 1 ;;
      *) warn "please answer y or n" ;;
    esac
  done
}

# prompt [-s] "question" ["default"] -- the answer lands in $ANSWER. With -s the
# terminal echo is off while it is typed, and a Ctrl-C meanwhile turns echo back
# on before leaving, so an abandoned run does not leave the shell typing blind.
prompt() {
  _hide=; [ "$1" = -s ] && { _hide=1; shift; }
  _def="${2:-}"
  while :; do
    printf "%s%s: " "$1" "${_def:+ [$_def]}" >&2
    if [ -n "$_hide" ]; then
      trap 'stty echo 2>/dev/null; printf "\n" >&2; exit 130' INT
      stty -echo 2>/dev/null
    fi
    read -r ANSWER || die "no answer on stdin"
    if [ -n "$_hide" ]; then
      stty echo 2>/dev/null; printf "\n" >&2
      trap - INT
    fi
    ANSWER="${ANSWER:-$_def}"
    [ -n "$ANSWER" ] && return 0
    warn "a value is required"
  done
}

# poll N cmd... -- runs cmd every 5s until it succeeds, giving up after N tries.
poll() {
  _left="$1"; shift
  until "$@"; do
    _left=$((_left - 1))
    [ "$_left" -gt 0 ] || return 1
    sleep 5
  done
}
