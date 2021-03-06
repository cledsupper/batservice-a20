#    This file is part of BatService.
#
#    BatService is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    BatService is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with BatService.  If not, see <https://www.gnu.org/licenses/>.


user_configs () { :; }
[ -r "$DATA/user-configs.sh" ] && . "$DATA/user-configs.sh"

CONFIG_FILE="$DATA/config.txt"

config_valid_param () {
  if echo $1 | grep -Ev '^[[:alpha:]\-]+$' >/dev/null; then
    printerr "config_number_set: o nome da variável deve conter somente letras e traços (-); recebeu: $1"
    error $E_INVPARAM
  fi
}

config_number_get () {
  if [ -r "$CONFIG_FILE" ]; then
    grep -E "^ *$1 +[[:digit:]]+ *$" "$CONFIG_FILE" | grep -Eo '[[:digit:]]+'
    return 0
  fi
  return 1
}

config_number_set () {
  config_valid_param $1
  local inval=$(echo $2 | grep -Ev '^[[:digit:]]+$')
  if [ -z "$2" -o -n "$inval" ]; then
    printerr "config_number_set: o valor deve ser um número; recebeu: $2"
    error $E_INVPARAM
  fi

  local val=$(config_number_get $1)
  if [ -z "$val" ]; then
    echo $1 $2 >> "$CONFIG_FILE"
    return $?
  fi
  sed -Ei "s|($1) .+|\1 $2|g" "$CONFIG_FILE"
  return $?
}

config_bool_get () {
  if [ -r "$CONFIG_FILE" ]; then
    local val
    val=$(grep -E "^ *$1 (true|false) *$" "$CONFIG_FILE")
    if [ -n "$val" ]; then
      echo "$val" | grep -Eo "(true|false)"
      return 0
    fi
  fi
  return 1
}

config_bool_set () {
  config_valid_param $1
  local inval=$(echo $2 | grep -Ev '^(true|false)$')
  if [ -z "$2" -o -n "$inval" ]; then
    printerr "config_number_set: o valor deve ser um booleano (true|false); recebeu: $2"
    error $E_INVPARAM
  fi

  local val=$(config_bool_get $1)
  if [ -z "$val" ]; then
    echo $1 $2 >> "$CONFIG_FILE"
    return $?
  fi
  sed -Ei "s|($1) .+|\1 $2|g" "$CONFIG_FILE"
}

config_string_get () {
  if [ -r "$CONFIG_FILE" ]; then
    grep $1 "$CONFIG_FILE" | sed -E "s/$1 (.+)/\1/g"
    return 0
  fi
  return 1
}

# Strings multilinha não são suportadas
config_string_set () {
  config_valid_param $1
  if [ -z "$2" ]; then
    printerr "config_string_set: a string não pode ser vazia!"
    error $E_INVPARAM
  fi

  local val="$(config_string_get $1)"
  if [ -z "$val" ]; then
    echo $1 "$2" >> "$CONFIG_FILE"
    return $?
  fi
  sed -Ei "s/($1) .+/\1 $2/g" "$CONFIG_FILE"
}


CHARGE_NEVER_STOP=$DISABLED
CHARGE_CONTINUE=45
CHARGE_STOP=50

if [ -z "$TERMUX_API" ]; then
  SRV_DELAY=60
else
  SRV_DELAY=10
fi

_config_update=0

config_refresh () {
  if [ -r "$CONFIG_FILE" ]; then
    local changed=$(stat -c "%Y" "$CONFIG_FILE")
    if [ $changed -le $_config_update ]; then
      return 0
    fi

    _config_update=$changed

    local never_stop
    never_stop=$(config_bool_get charge-never-stop)
    if [ -z "$never_stop" ]; then
      :
    else
      [ "$never_stop" = "true" ] && CHARGE_NEVER_STOP=$ENABLED || CHARGE_NEVER_STOP=$DISABLED
    fi

    local cont
    local stop
    cont=$(config_number_get charge-continue)
    stop=$(config_number_get charge-stop)

    if [ -z "$cont" -o -z "$stop" ]; then
      :
    elif [ $cont -lt 15 -o $stop -le $cont -o $stop -gt 100 ]; then
      printerr "Arquivo de configuração mal definido!"
    else
      CHARGE_CONTINUE=$cont
      CHARGE_STOP=$stop
    fi

    local delay
    delay=$(config_number_get service-delay-not-charging)
    if [ -z "$delay" ]; then
      :
    elif [ $delay -lt 6 -o $delay -gt 60 ]; then
      printerr "O tempo ocioso deve ser ser digitado em segundos, de 6 a 60 segundos"
    else
      SRV_DELAY=$delay
    fi

    user_configs
  fi
}
