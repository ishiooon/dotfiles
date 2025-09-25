# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
# Functions
add-zsh-hook () {
	emulate -L zsh
	local -a hooktypes
	hooktypes=(chpwd precmd preexec periodic zshaddhistory zshexit zsh_directory_name) 
	local usage="Usage: add-zsh-hook hook function\nValid hooks are:\n  $hooktypes" 
	local opt
	local -a autoopts
	integer del list help
	while getopts "dDhLUzk" opt
	do
		case $opt in
			(d) del=1  ;;
			(D) del=2  ;;
			(h) help=1  ;;
			(L) list=1  ;;
			([Uzk]) autoopts+=(-$opt)  ;;
			(*) return 1 ;;
		esac
	done
	shift $(( OPTIND - 1 ))
	if (( list ))
	then
		typeset -mp "(${1:-${(@j:|:)hooktypes}})_functions"
		return $?
	elif (( help || $# != 2 || ${hooktypes[(I)$1]} == 0 ))
	then
		print -u$(( 2 - help )) $usage
		return $(( 1 - help ))
	fi
	local hook="${1}_functions" 
	local fn="$2" 
	if (( del ))
	then
		if (( ${(P)+hook} ))
		then
			if (( del == 2 ))
			then
				set -A $hook ${(P)hook:#${~fn}}
			else
				set -A $hook ${(P)hook:#$fn}
			fi
			if (( ! ${(P)#hook} ))
			then
				unset $hook
			fi
		fi
	else
		if (( ${(P)+hook} ))
		then
			if (( ${${(P)hook}[(I)$fn]} == 0 ))
			then
				typeset -ga $hook
				set -A $hook ${(P)hook} $fn
			fi
		else
			typeset -ga $hook
			set -A $hook $fn
		fi
		autoload $autoopts -- $fn
	fi
}
delete_from_history () {
	local cmd="$1" 
	awk -v cmd="$cmd" '!index($0, cmd)' ~/.zsh_history > ~/.zsh_history.tmp
	mv ~/.zsh_history.tmp ~/.zsh_history
	fc -R ~/.zsh_history
}
gawklibpath_append () {
	[ -z "$AWKLIBPATH" ] && AWKLIBPATH=`gawk 'BEGIN {print ENVIRON["AWKLIBPATH"]}'` 
	export AWKLIBPATH="$AWKLIBPATH:$*" 
}
gawklibpath_default () {
	unset AWKLIBPATH
	export AWKLIBPATH=`gawk 'BEGIN {print ENVIRON["AWKLIBPATH"]}'` 
}
gawklibpath_prepend () {
	[ -z "$AWKLIBPATH" ] && AWKLIBPATH=`gawk 'BEGIN {print ENVIRON["AWKLIBPATH"]}'` 
	export AWKLIBPATH="$*:$AWKLIBPATH" 
}
gawkpath_append () {
	[ -z "$AWKPATH" ] && AWKPATH=`gawk 'BEGIN {print ENVIRON["AWKPATH"]}'` 
	export AWKPATH="$AWKPATH:$*" 
}
gawkpath_default () {
	unset AWKPATH
	export AWKPATH=`gawk 'BEGIN {print ENVIRON["AWKPATH"]}'` 
}
gawkpath_prepend () {
	[ -z "$AWKPATH" ] && AWKPATH=`gawk 'BEGIN {print ENVIRON["AWKPATH"]}'` 
	export AWKPATH="$*:$AWKPATH" 
}
hf () {
	local selected_output
	local selected_command
	local pressed_key
	echo -e "\033[1;34m●\033[0m \033[1;36m-fzf\033[0m"
	filter_history () {
		grep --color=auto -a -vE '^(HISTFILE=|HISTCONTROL=|shopt -s histappend|HISTSIZE=|HISTFILESIZE=|PROMPT_COMMAND="history -a|SAVEHIST=|setopt|set -o history|#|HISTIGNORE=)'
	}
	selected_output=$(cat ~/.zsh_history | cut -d';' -f2- | filter_history | awk '!seen[$0]++' | tac | fzf \
    --layout=reverse \
    --border=rounded \
    --prompt="🔍 " \
    --pointer="▶" \
    --marker="✓" \
    --header="履歴 | ENTER: 実行 | TAB: コマンドラインに挿入 | CTRL-D: 履歴から削除 | CTRL-R: 履歴更新" \
    --header-first \
    --query="" \
    --color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#88C0D0,fg:#D8DEE9,header:#616E88,info:#81A1C1,pointer:#81A1C1,marker:#A3BE8C,fg+:#D8DEE9,prompt:#81A1C1,hl+:#88C0D0 \
    --bind "ctrl-d:reload(~/.zsh/scripts/delete_history_entry.sh {})" \
    --bind "ctrl-r:execute-silent(echo -e '\033[1;32m履歴を更新しました\033[0m' >&2)+reload(cat ~/.zsh_history | cut -d';' -f2- | grep -a -vE '^(HISTFILE=|HISTCONTROL=|shopt -s histappend|HISTSIZE=|HISTFILESIZE=|PROMPT_COMMAND=\"history -a|SAVEHIST=|setopt|set -o history|#|HISTIGNORE=)' | awk '!seen[\$0]++' | tac)" \
    --expect=tab,enter) 
	pressed_key=$(head -1 <<< "$selected_output") 
	selected_command=$(tail -n +2 <<< "$selected_output" | sed 's/^[[:space:]]//') 
	if [[ -n "$selected_command" ]]
	then
		if [[ "$pressed_key" == "tab" ]]
		then
			echo -e "\033[1;36mInsert \033[0m➡ \033[1;33m$selected_command\033[0m"
			print -s "$selected_command"
			print -z "$selected_command"
		elif [[ "$pressed_key" == "enter" ]]
		then
			echo -e "\033[1;36mExec \033[0m➡ \033[1;33m$selected_command\033[0m"
			print -s "$selected_command"
			eval "$selected_command"
		fi
	fi
}
history-search-end () {
	# undefined
	builtin autoload -X
}
ml () {
	module ml "$@"
}
module () {
	unset _mlshdbg
	if [ "${MODULES_SILENT_SHELL_DEBUG:-0}" = '1' ]
	then
		case "$-" in
			(*v*x*) set +vx
				_mlshdbg='vx'  ;;
			(*v*) set +v
				_mlshdbg='v'  ;;
			(*x*) set +x
				_mlshdbg='x'  ;;
			(*) _mlshdbg=''  ;;
		esac
	fi
	unset _mlre _mlIFS
	if [ -n "${IFS+x}" ]
	then
		_mlIFS=$IFS 
	fi
	IFS=' ' 
	for _mlv in ${=MODULES_RUN_QUARANTINE:-}
	do
		if [ "${_mlv}" = "${_mlv##*[!A-Za-z0-9_]}" -a "${_mlv}" = "${_mlv#[0-9]}" ]
		then
			if [ -n "`eval 'echo ${'$_mlv'+x}'`" ]
			then
				_mlre="${_mlre:-}${_mlv}_modquar='`eval 'echo ${'$_mlv'}'`' " 
			fi
			_mlrv="MODULES_RUNENV_${_mlv}" 
			_mlre="${_mlre:-}${_mlv}='`eval 'echo ${'$_mlrv':-}'`' " 
		fi
	done
	if [ -n "${_mlre:-}" ]
	then
		eval `eval ${=_mlre} /usr/bin/tclsh /usr/share/Modules/libexec/modulecmd.tcl zsh '"$@"'`
	else
		eval `/usr/bin/tclsh /usr/share/Modules/libexec/modulecmd.tcl zsh "$@"`
	fi
	_mlstatus=$? 
	if [ -n "${_mlIFS+x}" ]
	then
		IFS=$_mlIFS 
	else
		unset IFS
	fi
	unset _mlre _mlv _mlrv _mlIFS
	if [ -n "${_mlshdbg:-}" ]
	then
		set -$_mlshdbg
	fi
	unset _mlshdbg
	return $_mlstatus
}
prompt_starship_precmd () {
	STARSHIP_CMD_STATUS=$? STARSHIP_PIPE_STATUS=(${pipestatus[@]}) 
	if (( ${+STARSHIP_START_TIME} ))
	then
		__starship_get_time && (( STARSHIP_DURATION = STARSHIP_CAPTURED_TIME - STARSHIP_START_TIME ))
		unset STARSHIP_START_TIME
	else
		unset STARSHIP_DURATION STARSHIP_CMD_STATUS STARSHIP_PIPE_STATUS
	fi
	STARSHIP_JOBS_COUNT=${#jobstates} 
}
prompt_starship_preexec () {
	__starship_get_time && STARSHIP_START_TIME=$STARSHIP_CAPTURED_TIME 
}
scl () {
	if [ "$1" = "load" -o "$1" = "unload" ]
	then
		eval "module $@"
	else
		/usr/bin/scl "$@"
	fi
}
starship_zle-keymap-select () {
	zle reset-prompt
}
switchml () {
	typeset swfound=1 
	if [ "${MODULES_USE_COMPAT_VERSION:-0}" = '1' ]
	then
		typeset swname='main' 
		if [ -e /usr/share/Modules/libexec/modulecmd.tcl ]
		then
			typeset swfound=0 
			unset MODULES_USE_COMPAT_VERSION
		fi
	else
		typeset swname='compatibility' 
		if [ -e /usr/share/Modules/libexec/modulecmd-compat ]
		then
			typeset swfound=0 
			MODULES_USE_COMPAT_VERSION=1 
			export MODULES_USE_COMPAT_VERSION
		fi
	fi
	if [ $swfound -eq 0 ]
	then
		echo "Switching to Modules $swname version"
		source /usr/share/Modules/init/zsh
	else
		echo "Cannot switch to Modules $swname version, command not found"
		return 1
	fi
}
which () {
	(
		alias
		eval ${which_declare}
	) | /usr/bin/which --tty-only --read-alias --read-functions --show-tilde --show-dot $@
}
zshaddhistory () {
	local line="${1%%$'\n'}" 
	[[ "$line" =~ ^(HISTFILE=|HISTCONTROL=|shopt\ -s\ histappend|HISTSIZE=|HISTFILESIZE=|PROMPT_COMMAND=|SAVEHIST=|setopt|set\ -o\ history|#|HISTIGNORE=) ]] && return 1
	return 0
}
# Shell Options
setopt nohashdirs
setopt histignoredups
setopt login
setopt promptsubst
setopt sharehistory
# Aliases
alias -- claude-code='~/.bin/claude-code-wrapper'
alias -- clean-history='~/.bin/clean_history.sh'
alias -- egrep='egrep --color=auto'
alias -- fgrep='fgrep --color=auto'
alias -- gh=/usr/local/bin/gh
alias -- grep='grep --color=auto'
alias -- l='ls -CF'
alias -- la='ls -A'
alias -- ll='ls -alF'
alias -- ls='ls --color=auto'
alias -- run-help=man
alias -- which-command=whence
alias -- xzegrep='xzegrep --color=auto'
alias -- xzfgrep='xzfgrep --color=auto'
alias -- xzgrep='xzgrep --color=auto'
alias -- zegrep='zegrep --color=auto'
alias -- zfgrep='zfgrep --color=auto'
alias -- zgrep='zgrep --color=auto'
# Check for rg availability
if ! command -v rg >/dev/null 2>&1; then
  alias rg='/usr/lib/node_modules/\@anthropic-ai/claude-code/vendor/ripgrep/x64-linux/rg'
fi
export PATH=/home/dev_local/.local/bin\:/home/dev_local/.deno/bin\:/home/dev_local/.local/share/nvim/mason/bin\:/home/dev_local/.local/bin\:/home/dev_local/.deno/bin\:/home/dev_local/.local/bin\:/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin
