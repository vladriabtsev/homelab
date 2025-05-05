# https://github.com/politza/ealias

## Copyright (C) 2016  Andreas Politz

## Author: Andreas Politz <politza@hochschule-trier.de>

## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.

## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

# An ealias is an alias, which expands to an invocation of
# `emacsclient --eval' with an appropriate arguments.  See function
# _ealias_help.


# File aliases saved with the -w flag.
EALIAS_RC=${EALIAS_RC-~/.config/ealiasrc};

# Hash with ealias names as keys and their expansion as values.
if [ -z "${EALIAS_ALIASES[*]}" ]; then
    declare -A EALIAS_ALIASES
    EALIAS_ALIASES=()
fi

# Define an Emacs alias.
ealias()
{
    
    local name=${1%%=*}
    local spec=${1#*=}

    if [ $# -gt 1 ] ; then
        _ealias_usage
        return 1
    elif [ $# -eq 0 ] || [ "$1" = "-p" ]; then
        _ealias_print
        return 0
    elif [ "$1" = "--help" ]; then
        _ealias_help
        return 0
    elif [[ "$1" == -[ewr] ]]; then
        if [ -z "$EALIAS_RC" ]; then
            echo "\$EALIAS_RC is not set" >&2
            return 1
        fi
        if [ "$1" = "-e" ]; then
            "${EALIAS_CLIENT:-emacsclient}" "$EALIAS_RC"
            return 0
        elif [ "$1" = "-w" ]; then
            echo '#!/bin/bash' > "$EALIAS_RC" && \
                _ealias_print >> "$EALIAS_RC" &&  echo "Wrote $EALIAS_RC" >&2
            return $?
        elif [ "$1" = "-r" ]; then
            PATH= source "$EALIAS_RC" && echo "Read $EALIAS_RC" >&2
            return $?
        fi
    elif [ "${name:0:1}" = "-" ]; then
        _ealias_usage
        return 1
    elif [ "$name" = "$1" ]; then
        _ealias_print "$name"
        return $?
    fi

    EALIAS_ALIASES[$name]=$spec
    eval "_ealias_fn_$name() { _ealias_execute '$name' \"\$@\"; }"
    alias "$name"="_ealias_fn_$name"
    
    return 0
}

_ealias_usage()
{
    cat <<'EOF'
usage:ealias [-[pnws] | --help | name | name=spec]
EOF
}

_ealias_help()
{
    _ealias_usage
    cat << 'EOF'

    Define or display Emacs aliases.

    Without arguments, `ealias' prints the list of Emacs aliases in
    the reusable form `ealias NAME=SPEC' to standard output.

    If only NAME is given, print just it's definition.

    Otherwise, an alias is defined for NAME according to SPEC in the
    following way: The first word is taken as the function, which is
    to be called with the remaining string as arguments.  These
    arguments are evaluated when emacsclient is invoked.  SPEC may
    contain special format codes, all starting with a `%', similar to
    printf.  These are substituted for various constructs at the time
    the alias is executed with a given argument list, as follows:

      %^        Pop the next argument and use it as a string. 

      %@        Use the remaining arguments as a list of strings.

      %*        Use the remaining arguments as a single string.

      %1 .. %9  Use the nth argument as a string.

      %%        Insert a literal `%'.

    Every alias defines a Bash function, which will invoke the
    emacsclient program with arguments according to SPEC. Unless the
    first argument is `-n', in which case the resulting command is
    only printed.

    The program to use as emacsclient may be set via the environment
    variable EALIAS_CLIENT.
    
    Options:

      -p     Print all defined Emacs aliases in a reusable format.
      -n     Only print what would be executed (dry-run).
      -r     Read ealias definitions from file $EALIAS_RC .
      -w     Write current definitions to file $EALIAS_RC, overwriting it.
      -e     Edit the $EALIAS_RC file.
      --help Print this message.
    
    Example:

      ealias rgrep='rgrep %^ %* \"$PWD\"'

    Use the first argument as REGEXP, the rest as FILES and $PWD as
    DIR argument (see rgrep Emacs function).  Note that the quotes
    need to be escaped, since the whole SPEC is evaluated.

    After this definition a command like

      rgrep printf \*.c \*.h

    will expand into

      emacsclient --eval "(rgrep \"printf\" \"*.c *.h\" \"$PWD\")"
    
    The following, slightly silly, example creates an alias, which
    adds up all arguments as numbers.

      ealias eplus='apply '\''+ $* nil'

    Since this alias does not pass any strings, the regular shell
    parameter substitution is sufficient. Let's see if it works as
    expected:

      $ eplus -n $(seq 1 4)
      emacsclient --eval (apply '+ 1 2 3 4 nil)
      $ eplus $(seq 1 4)
      10
       
    Exit Status:

    ealias returns true, unless trying to print an undefined alias or
    some other error happened.

    See also:

    `eunalias' to remove a defined Emacs alias.
EOF
}

# Remove an Emacs alias
eunalias()
{
    if [ $# -ne 1 ]; then
        echo "usage:eunalias NAME"
        return 1;
    fi

    local name=$1
    
    if [ -n "${EALIAS_ALIASES[$name]}" ]; then
        unset EALIAS_ALIASES[$name]
        unset -f "$name"
        unalias $name
        return 0
    fi
    echo "No such alias: $name" >&2
    return 1
}


_ealias_print()
{
    if [ $# -gt 1 ]; then
        echo "usage:$FUNCNAME [name]" >&2
        return 1
    fi

    if [ $# -eq 0 ]; then
        set -- "${!EALIAS_ALIASES[@]}"
    fi
    
    for name ; do
        spec="${EALIAS_ALIASES[$name]}"
        if [ -z "$spec" ]; then
            echo "No such alias: $name" >&2
            return 1
        fi
        echo "ealias $name='${spec/\'/\'\\\'\'}'" 
    done | sort
    return 0
}

_ealias_execute()
{
    local spec eargs fn s i
    local noexec                # Just print what would be executed.

    name=$1; shift
    spec=${EALIAS_ALIASES[$name]}

    if [ -z "$spec" ]; then
        echo "No such alias: $name" >&2
        return 1;
    fi
    
    fn=${spec%% *}
    eargs=${spec#* }
    if [ "$fn" == "$spec" ]; then
        eargs=
    fi
    i=1

    # Process and shift our arguments.
    while [ $# -gt 0 ]; do
        case $1 in
            -n)
                noexec=1 ;;
            --)
                shift
                break ;;
            --help)
                _ealias_print "$name"
                return 0 ;;
            *)
                break ;;
        esac
        shift
    done

    i=0
    # Substitue %x formats
    while [ $i -lt ${#eargs} ]; do
        if [ "${eargs:$i:1}" = "%" ]; then
            local fmt=${eargs:$i + 1:1}
            local arg=
            case $fmt in
                [@])
                    local rest=()
                    for arg; do
                        rest+=("\\\"$arg\\\"")
                    done
                    arg="'(${rest[*]})"
                    ;;
                [*])
                    arg="\\\"$*\\\"" ;;
                [0-9])
                    arg="\\\"${!fmt}\\\"" ;;
                [\^])
                    arg="\\\"$1\\\""
                    shift
                    ;;
                [%])
                    arg=% ;;
		*)
                    echo "Invalid format code: \`${eargs:$i:2}'"
                    return 1
                    ;;
            esac 
            # Delete format, insert arg and skip over it.
            eargs=${eargs:0:$i}$arg${eargs:$i + 2}
            let i+=${#arg}-1
        fi
        let ++i
    done

    if [ -n "$noexec" ]; then
        eval "echo ${EALIAS_CLIENT:-emacsclient} --eval \"($fn ${eargs})\""
    else
        eval "${EALIAS_CLIENT:-emacsclient} --eval \"($fn ${eargs})\""
    fi
}

_ealias()
{
    COMPREPLY=("${!EALIAS_ALIASES[@]}")
}

complete -F _ealias ealias
complete -F _ealias eunalias

