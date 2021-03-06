#    user-events.sh - eventos do BateriaDroid
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


U_PERCENT_WEAK=20

# 3,7 V => 14 %
U_VOLTAGE_FOR_14PERC=3700
# O percentual deve ser maior que 19 % para identificar erro
U_PERCENT_ERR_MAX=19

# Aqui, nós corrigiremos o percentual da bateria
user_events_pre () {
  if [ -n "$U_CHARGE_EMPTY" ]; then
    battery_charge_now
    battery_charge_full
    local Pi=$charge_now
    local Ti=$charge_full
    local D=$U_CHARGE_EMPTY
    percent=$(expr '(' $Pi - $D ')' '*' 100 / '(' $Ti - $D ')')
    [ $percent -lt 0 ] && percent=0
  fi
}

# Verificar se a bateria está fraca/vazia e propagar isto caso necessário
charge_empty_action () {
  if [ $voltage -lt $U_VOLTAGE_FOR_14PERC -a $percent -ge $U_PERCENT_ERR_MAX ]; then
    battery_charge_now
    battery_charge_full
    local Pi=$charge_now
    local Ti=$charge_full
    local D=$(expr '(' 100 '*' $Pi -  14 '*' $Ti ')' / 86)
    local Tf=$(expr $Ti - $D)

    config_number_set charge-empty $D
    echo '#upd a bateria foi calibrada para o serviço'
    echo "#msg Capacidade da bateria: $Tf mAh"
    u_battery_is_weak=1
    return $EVENTS_NEXT
  fi

  if [ -z "$u_battery_is_weak" -a $percent -lt $U_PERCENT_WEAK ]; then
    echo '#upd bateria fraca!'
    echo '#msg A bateria está fraca, conecte o carregador'
    u_battery_is_weak=1
  elif [ -n "$u_battery_is_weak" -a $percent -ge $U_PERCENT_WEAK ]; then
    unset u_battery_is_weak
  fi
}

user_on_discharge () {
  charge_empty_action
  return $?
}
