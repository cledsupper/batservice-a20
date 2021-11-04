# startup-helper.sh - inicializador do serviço

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

SERVICE_CACHE="$MODDIR/log"

log_cleanup () {
  if [ -r "$SERVICE_CACHE/out.log" ]; then

    if [ $(stat -c "%s" "$SERVICE_CACHE/out.log") -gt 30000 ]; then
      sed -i 1,1700d "$SERVICE_CACHE/out.log"
      exec>> "$SERVICE_CACHE/out.log"
    fi
  fi
}

mkdir -p "$SERVICE_CACHE"

echo "  ====== REGISTRO" "$NAME" "======="\
  >> "$SERVICE_CACHE/out.log"

exec>> "$SERVICE_CACHE/out.log"

