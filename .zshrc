# Periodic auto-update on Zsh startup: 'ask' or 'no'.
# You can manually run `z4h update` to update everything.
zstyle ':z4h:' auto-update      'no'
# Ask whether to auto-update this often; has no effect if auto-update is 'no'.
zstyle ':z4h:' auto-update-days '28'
# Keyboard type: 'mac' or 'pc'.
zstyle ':z4h:bindkey' keyboard  'pc'

# Start tmux if not already in tmux.
# https://www.reddit.com/r/zsh/comments/14tlcnt/comment/k6y995w/?utm_source=share&utm_medium=web2x&context=3
if [[ "$TTY" == /dev/tty* ]]; then
  zstyle ':z4h:' start-tmux no
else
  zstyle ':z4h:' start-tmux command tmux -u new -D
fi

# zstyle ':z4h:' start-tmux no

# Whether to move prompt to the bottom when zsh starts and on Ctrl+L.
zstyle ':z4h:' prompt-at-bottom 'no'
# Mark up shell's output with semantic information.
zstyle ':z4h:' term-shell-integration 'yes'
# Right-arrow key accepts one character ('partial-accept') from
# command autosuggestions or the whole thing ('accept')?
zstyle ':z4h:autosuggestions' forward-char 'accept'
# Recursively traverse directories when TAB-completing files.
zstyle ':z4h:fzf-complete' recurse-dirs 'no'
# Enable direnv to automatically source .envrc files.
zstyle ':z4h:direnv'         enable 'no'
# Show "loading" and "unloading" notifications from direnv.
zstyle ':z4h:direnv:success' notify 'yes'
# The default value if none of the overrides above match the hostname.
zstyle ':z4h:ssh:*'                   enable 'no'

zstyle ':z4h:fzf-complete' recurse-dirs yes
zstyle ':z4h:*' fzf-flags --color=hl:9,hl+:5

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
# initialize Zsh. After this point console I/O is unavailable until Zsh
# is fully initialized. Everything that requires user interaction or can
# perform network I/O must be done above. Everything else is best done below.
z4h init || return

path=(~/bin $path)

export GPG_TTY=$TTY
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.config/emacs/bin:$PATH"
export EDITOR="emacsclient --create-frame"
export XDG_CURRENT_DESKTOP=KDE
# to use gpg smart card for ssh
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
# https://github.com/junegunn/fzf#key-bindings-for-command-line
# display Alt-C as a tree
export FZF_ALT_C_OPTS="--preview 'tree -C {}'"

# Source additional local files if they exist.
z4h source ~/.env.zsh

# Define key bindings.
z4h bindkey z4h-backward-kill-word  Ctrl+Backspace     Ctrl+H
z4h bindkey z4h-backward-kill-zword Ctrl+Alt+Backspace

z4h bindkey undo Ctrl+/ Shift+Tab  # undo the last command line change
z4h bindkey redo Alt+/             # redo the last undone command line change

z4h bindkey z4h-cd-back    Alt+Left   # cd into the previous directory
z4h bindkey z4h-cd-forward Alt+Right  # cd into the next directory
z4h bindkey z4h-cd-up      Alt+Up     # cd into the parent directory
z4h bindkey z4h-cd-down    Alt+Down   # cd into a child directory

# Autoload functions.
autoload -Uz zmv

# Define functions and completions.
md(){[[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"}
compdef _directories md

# Define aliases.
alias tree='tree -a -I .git'

# Add flags to existing aliases.
alias ls="${aliases[ls]:-ls} -A"

# prevent fasd from aliasing sd
alias sd=/usr/bin/sd
alias docker=podman
alias b="bat --wrap never"
alias py=python3
# search dotfiles by default
alias fd='fd -H -I'
alias ll='ls -alF'
alias ls='exa --icons'

alias o=xdg-open

# default pass coffin open function to close after 1 minute
# https://superuser.com/questions/105375/how-to-use-spaces-in-a-bash-alias-name
pass() {
    if [[ $@ == "open" ]] && [[ "$#" -eq 1 ]]; then
        command pass open -t 1min
    else
        command pass "$@"
    fi
}

# https://unix.stackexchange.com/questions/489445/unzip-to-a-folder-with-the-same-name-as-the-file-without-the-zip-extension
unzip_d() {
       	zipfile="$1"
	zipdir=${1%.zip}
	unzip -d "$zipdir" "$zipfile"
}

e(){(emacsclient --create-frame $1 & >/dev/null 2>&1)}

ee(){emacsclient --create-frame $1 & exit}

# quickly make a file in some chosen location with a timestamp
# append to it text given in arguments and open emacsclient
mktemppy(){
  MKTEMPPY=$(mktemp -p ~/scripts/temp --suffix .py)
  printf "%s" "$@" >> $MKTEMPPY
  (emacsclient --create-frame $MKTEMPPY & >/dev/null 2>&1)
  printf $MKTEMPPY | xclip -selection clipboard
  echo $MKTEMPPY
}

# same as above, but concatenated and stripped of whitespace - maybe will be useful
kscat(){
  CAT=""
  for i in $@
  do
      CAT+=$(qdbus org.kde.klipper /klipper org.kde.klipper.klipper.getClipboardHistoryItem "$i")
  done
  echo $CAT
}

# python's strip
pystrip(){python -c "[print(i.strip()) for i in open(0)]"}

# I've ended up relying on z4h's dir history (Alt+R) instead:
#quickly jump to recent directories
#uses fzf for fuzzy finding and fasd to record frecent directories
#fasd: -l argument lists only directories and -t lists by most recent
#when written as alias and not a function it runs on each new shell
# cdf(){cd "$(fasd -ltR | fzf)"}


# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots     # no special treatment for file names with a leading dot
setopt no_auto_menu  # require an extra TAB press to open the completion menu

# https://unix.stackexchange.com/questions/273861/unlimited-history-in-zsh
HISTFILE="$HOME/.zsh_history"
HISTFILESIZE=1000000000
HISTSIZE=1000000000
SAVEHIST=1000000000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
# setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
# setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
# setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
# setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.

setopt HIST_BEEP                 # Beep when accessing nonexistent history.

# https://www.reddit.com/r/zsh/comments/12ft7om/conditional_rewriting_parts_of_the_command_line/
.zle_winpaths(){
    local words=(${(z)BUFFER})
    local newwords=()
    for word ( $words ) {
        if [[ $word != /mnt/c/* ]] {
            newwords+=($word)
            continue
        }
        newwords+=(C:'\\'${${word#/mnt/c/}//\//'\\'})
    }
    BUFFER=${(j: :)newwords}
    CURSOR=$#BUFFER
}
zle -N .zle_winpaths

# https://www.reddit.com/r/zsh/comments/12ft7om/conditional_rewriting_parts_of_the_command_line/
# https://linux.die.net/man/1/zshexpn
rclone-path-convert(){
    # split buffer using "shell semantics" (quotes will be recognized)
    local words=(${(z)BUFFER})
    local newwords=()
    # (Q) - Remove one level of quotes from the resulting words.
    for word ( ${(Q)words} ) {
        if [[ ! -e $word ]] {
            newwords+=($word)
            continue
        }
        rclone_fs_name=$(df "$word" | sed 1d | awk '{print $1}')
        rclone_mount_path=$(df "$word" | sed 1d | awk '{print $NF}')
        rclone_rel_path=${"$(readlink -f $word)"#$rclone_mount_path}
        newwords+=\'$rclone_fs_name$rclone_rel_path\'
    }
    # join array with " " whitespace character
    BUFFER=${(j: :)newwords}
    CURSOR=$#BUFFER
}
zle -N rclone-path-convert

rclone-path-variable(){
    # split buffer using "shell semantics" (quotes will be recognized)
    local words=(${(z)BUFFER})
    local newwords=()
    # (Q) - Remove one level of quotes from the resulting words.
    for word ( ${(Q)words} ) {
        if [[ ! -e $word ]] {
            newwords+=($word)
            continue
        }
        rclone_fs_name=$(df "$word" | sed 1d | awk '{print $1}')
        mountpoint=$(df "$word" | sed 1d | awk '{print $NF}')
        # / slash at the end removes it from the beginning of rclone_rel_path
        rclone_rel_path=${"$(readlink -f $word)"#$mountpoint/}
        newwords+=$rclone_fs_name\$rclone_rel_path
    }
    # join array with " " whitespace character
    BUFFER='rclone_rel_path='\'$rclone_rel_path\''; '${(j: :)newwords}
    CURSOR=$#BUFFER
}
zle -N rclone-path-variable

rclone-crypt-path-variable(){
    # split buffer using "shell semantics" (quotes will be recognized)
    local words=(${(z)BUFFER})
    local newwords=()
    # (Q) - Remove one level of quotes from the resulting words.
    for word ( ${(Q)words} ) {
        if [[ ! -e $word ]] {
            newwords+=($word)
            continue
        }
        rclone_fs_name=$(df "$word" | sed 1d | awk '{print $1}')
        rclone_fs_mountpoint=$(df "$word" | sed 1d | awk '{print $NF}')
        # / slash at the end removes it from the beginning of rclone_rel_path
        rclone_rel_path=${"$(readlink -f $word)"#$rclone_fs_mountpoint/}

        # this assumes that you are using rclone config in default location
        # tests is file belongs to a crypt or union type of remote
        rclone_remote_type=$(awk '/^\['${rclone_fs_name%:}'\]/{f=1} f==1&&/^type/{print $3;exit}' ~/.config/rclone/rclone.conf)
        if [[ $rclone_remote_type == "union" ]]; then
          # this always reads the first remote in "upstreams" entry
          # it should check if file belongs to that remote instead
          rclone_remote=$(awk '/^\['${rclone_fs_name%:}'\]/{f=1} f==1&&/^upstreams/{print $3;exit}' ~/.config/rclone/rclone.conf)
        elif [[ $rclone_remote_type == "crypt" ]]; then
          rclone_remote=$rclone_fs_name
        else
          continue
        fi

        rclone_rel_path_crypt=$(rclone cryptdecode --reverse $rclone_remote $rclone_rel_path | awk '{print $NF}')
        newwords+='gdrive:crypt/'\$rclone_rel_path_crypt
    }
    # join array with " " whitespace character
    BUFFER='rclone_rel_path_crypt='\'$rclone_rel_path_crypt\''; '${(j: :)newwords}
    CURSOR=$#BUFFER
}
zle -N rclone-crypt-path-variable

rclone-restore-aws-crypt(){
    local words=(${(z)BUFFER})
    local newwords=()
    for word ( ${(Q)words} ) {
        if [[ ! -e $word ]] {
            newwords+=($word)
            continue
        }
        rclone_fs_name=$(df "$word" | sed 1d | awk '{print $1}')
        rclone_fs_mountpoint=$(df "$word" | sed 1d | awk '{print $NF}')
        # / slash at the end removes it from the beginning of rclone_rel_path
        rclone_rel_path=${"$(readlink -f $word)"#$rclone_fs_mountpoint/}

        # this assumes that you are using rclone config in default location
        # tests is file belongs to a crypt or union type of remote
        rclone_remote_type=$(awk '/^\['${rclone_fs_name%:}'\]/{f=1} f==1&&/^type/{print $3;exit}' ~/.config/rclone/rclone.conf)
        if [[ $rclone_remote_type == "union" ]]; then
          # this always reads the first remote in "upstreams" entry
          # it should check if file belongs to that remote instead
          rclone_remote=$(awk '/^\['${rclone_fs_name%:}'\]/{f=1} f==1&&/^upstreams/{print $3;exit}' ~/.config/rclone/rclone.conf)
        elif [[ $rclone_remote_type == "crypt" ]]; then
          rclone_remote=$rclone_fs_name
        else
          continue
        fi

        rclone_rel_path_crypt=$(rclone cryptdecode --reverse $rclone_remote $rclone_rel_path | awk '{print $NF}')
        rclone_rel_path_crypt_path=$(dirname $rclone_rel_path_crypt)
        newwords+='rclone backend restore aws-glacier-deep:tjspbukwhiocn/crypt/'$rclone_rel_path_crypt_path' --include /'$(basename $rclone_rel_path_crypt)
    }
    # join array with " " whitespace character
    BUFFER=${(j: :)newwords}' -o lifetime=1 -o priority=Bulk'
    CURSOR=$#BUFFER
}
zle -N rclone-restore-aws-crypt

# https://www.reddit.com/r/zsh/comments/13zazka/how_to_add_words_in_the_middle_of_the_buffer/
notmuch-rm(){
  emulate -L zsh
  # split buffer using "shell semantics" (quotes will be recognized)
  local words=(${(z)BUFFER})
  if [[ $words[1,2] == "notmuch search" ]] && BUFFER="$words[1,2] --output=files --format=text0 $words[3,-1] | xargs -r0 rm && notmuch new"
  if [[ $words[1] == "nms" ]] && BUFFER="$words[1] --output=files --format=text0 $words[2,-1] | xargs -r0 rm && notmuch new"
}
zle -N notmuch-rm

notmuch-open-thunderbird(){
  emulate -L zsh
  # split buffer using "shell semantics" (quotes will be recognized)
  local words=(${(z)BUFFER})
  # remember to escape the $ dollar signs you mean to add to the buffer
  if [[ $words[1,2] == "notmuch search" ]] && BUFFER="TMPSUFFIX=.eml; for i in \$($words[1,2] --output=files $words[3,-1]); do thunderbird =(cat \$i)& done"
}
zle -N notmuch-open-thunderbird

notmuch(){
    if [[ $1 == "search" ]]; then
      # remove "search" from "$@"
      shift 1
      command notmuch search --sort=oldest-first "$@"
    else
      command notmuch "$@"
    fi
}

alias nms="notmuch search"

alias mmv='noglob zmv -W'

tmpsuffix-eml(){
  local words=(${(z)BUFFER})
  local newwords=()
  # (Q) - Remove one level of quotes from the resulting words.
  for word ( ${(Q)words} ) {
      if [[ ! -e $word ]] {
          newwords+=($word)
          continue
      }
      # FILENAME.eml --> =(<"FILENAME.eml")
      newwords+="=(<\"$word\")"
  }
  # join array with " " whitespace character
  BUFFER=${(j: :)newwords}
  BUFFER="TMPSUFFIX=.eml; $BUFFER"
  # thunderbird forks so you need to disown it (and remove /tmp/zsh* leftover files)
  [[ $BUFFER =~ "thunderbird" ]] && BUFFER="$BUFFER &"
}
zle -N tmpsuffix-eml

tmpsuffix-eml-without-process-substitution(){
  BUFFER="TMPSUFFIX=.eml; $BUFFER"
}
zle -N tmpsuffix-eml-without-process-substitution

source /usr/share/doc/find-the-command/ftc.zsh

export LIBVIRT_DEFAULT_URI='qemu:///system'

replace-backslashes-with-forward-slashes(){
  BUFFER=${BUFFER:gs \\ /}
}
zle -N replace-backslashes-with-forward-slashes

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
