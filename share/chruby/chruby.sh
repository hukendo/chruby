#!/bin/bash
CHRUBY_VERSION="0.4.1"
RUBIES=()

for dir in "$PREFIX/opt/rubies" "$HOME/.rubies"; do
  [[ -d "$dir" && -n "$(ls -A "$dir")" ]] && RUBIES+=("$dir"/*)
done
unset dir

function chruby_reset(){
  [[ -z "$RUBY_ROOT" ]] && return

  PATH=":$PATH:"; PATH="${PATH//:$RUBY_ROOT\/bin:/:}"
  [[ -n "$GEM_ROOT" ]] && PATH="${PATH//:$GEM_ROOT\/bin:/:}"

  if (( UID != 0 )); then
    [[ -n "$GEM_HOME" ]] && PATH="${PATH//:$GEM_HOME\/bin:/:}"

    GEM_PATH=":$GEM_PATH:"
    [[ -n "$GEM_HOME" ]] && GEM_PATH="${GEM_PATH//:$GEM_HOME:/:}"
    [[ -n "$GEM_ROOT" ]] && GEM_PATH="${GEM_PATH//:$GEM_ROOT:/:}"
    GEM_PATH="${GEM_PATH#:}"; GEM_PATH="${GEM_PATH%:}"

    unset GEM_HOME
    [[ -z "$GEM_PATH" ]] && unset GEM_PATH
  fi

  PATH="${PATH#:}"; PATH="${PATH%:}"
  unset RUBY_ROOT RUBY_ENGINE RUBY_VERSION RUBYOPT GEM_ROOT
  hash -r
}


# export RUBY_ENGINE, RUBY_VERSION, GEM_ROOT
function chruby_env(){
RUBYGEMS_GEMDEPS="" $1 - <<EOF
puts "export RUBY_ENGINE=#{Object.const_defined?(:RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'};"
puts "export RUBY_VERSION=#{RUBY_VERSION};"
begin
  require 'rubygems'
  puts "export GEM_ROOT=#{Gem.default_dir.inspect};"
  rescue Exception
end
EOF
}

#usage chruby_export /path/to/ruby
#get current ruby export variables: chruby_export $(where ruby | head -1)
function chruby_export(){
  local RUBY_PATH="$1/bin/ruby"
  if [[ ! -x "$RUBY_PATH" ]]; then
    echo "chruby_export: $RUBY_PATH/bin/ruby not executable" >&2
    return 1
  fi
  <<EOF
export RUBYGEMS_GEMDEPS=-
export RUBY_ROOT="${RUBY_PATH%%/bin/ruby}"
export PATH="\$RUBY_ROOT/bin:\$PATH"
$(chruby_env "$RUBY_PATH")
export PATH="\${GEM_ROOT:+\$GEM_ROOT/bin:}\$PATH"
EOF
  if (( UID != 0 )); then
    cat<<EOF
export GEM_HOME="\$HOME/.gem/$RUBY_ENGINE/$RUBY_VERSION"
export GEM_PATH="\$GEM_HOME\${GEM_ROOT:+:\$GEM_ROOT}\${GEM_PATH:+:\$GEM_PATH}"
export PATH="\$GEM_HOME/bin:\$PATH"
EOF
  fi
}

function chruby_use(){
  set -x
  if [[ ! -x "$1/bin/ruby" ]]; then
    echo "chruby: $1/bin/ruby not executable" >&2
    return 1
  fi

  [[ -n "$RUBY_ROOT" ]] && chruby_reset

  export RUBY_ROOT="$1"
  export RUBYOPT="$2"
  export PATH="$RUBY_ROOT/bin:$PATH"
  eval "$(chruby_env $RUBY_ROOT/bin/ruby)"
  export PATH="${GEM_ROOT:+$GEM_ROOT/bin:}$PATH"

  if (( UID != 0 )); then
    export GEM_HOME="$HOME/.gem/$RUBY_ENGINE/$RUBY_VERSION"
    export GEM_PATH="$GEM_HOME${GEM_ROOT:+:$GEM_ROOT}${GEM_PATH:+:$GEM_PATH}"
    export PATH="$GEM_HOME/bin:$PATH"
  fi

  hash -r
  set +x
}

chruby_rubies(){
  local dir ruby ruby_path
    for dir in "${RUBIES[@]}"; do
      if [[ "$1" = "-p" ]]; then
        ruby_path="$dir"
      fi
      dir="${dir%%/}"; ruby="${dir##*/}"
      if [[ "$dir" == "$RUBY_ROOT" ]]; then
        #echo " *\t ${RUBYOPT} \t$ruby_path"
        printf " * %-20s\t%s\t%s\n" "${ruby}" "${RUBYOPT}" "$ruby_path"
      else
        #echo " -\t${ruby} \t$ruby_path" | column -t
        printf " - %-20s\t%s\t%s\n" "${ruby}" "" "$ruby_path"
      fi
    done
}

function chruby(){
  case "$1" in
    -h|--help)
      echo "usage: chruby [RUBY|VERSION|system] [RUBYOPT...]"
      ;;
    -v|--version)
      echo "chruby: $CHRUBY_VERSION"
      ;;
    "")
      chruby_rubies
      ;;
    "-p")
      chruby_rubies path
      ;;
    system) chruby_reset ;;
    *)
      local dir ruby match
      for dir in "${RUBIES[@]}"; do
        dir="${dir%%/}"; ruby="${dir##*/}"
        case "$ruby" in
          "$1")  match="$dir" && break ;;
          *"$1"*)  match="$dir" ;;
        esac
      done

      if [[ -z "$match" ]]; then
        echo "chruby: unknown Ruby: $1" >&2
        return 1
      fi

      shift
      chruby_use "$match" "$*"
      ;;
  esac
}
