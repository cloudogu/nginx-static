#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# Prints the cloudogu logo as ASCI art.
function printCloudoguLogo() {
  echo "                                     ./////,                    "
  echo "                                 ./////==//////*                "
  echo "                                ////.  ___   ////.              "
  echo "                         ,**,. ////  ,////A,  */// ,**,.        "
  echo "                    ,/////////////*  */////*  *////////////A    "
  echo "                   ////'        \VA.   '|'   .///'       '///*  "
  echo "                  *///  .*///*,         |         .*//*,   ///* "
  echo "                  (///  (//////)**--_./////_----*//////)   ///) "
  echo "                   V///   '°°°°      (/////)      °°°°'   ////  "
  echo "                    V/////(////////\. '°°°' ./////////(///(/'   "
  echo "                       'V/(/////////////////////////////V'      "
}

# Provides an easy function to create consistent log messages.
function log() {
  local message="${1}"
  echo "[nginx-static][startup] ${message}"
}

# Templates the maintenance mode site with the title and text provided in the etcd.
function configureMaintenanceModeSite() {
  log "Configure maintenance site..."

  local entryJSON=""
  entryJSON="$(doguctl config -g -d '{"title": "Service Unavailable", "text": "The EcoSystem is currently in maintenance mode."}' maintenance)"

  if [ "${entryJSON}" == "" ]; then
      return
  fi

  local title=""
  title="$(echo "${entryJSON}" | jq -r ".title")"
  doguctl config maintenance/title "${title}"

  local text=""
  text="$(echo "${entryJSON}" | jq -r ".text")"
  doguctl config maintenance/text "${text}"

  cp /var/www/html/errors/503.html /var/www/html/errors/503.html.tpl

  sed -i 's|Service Unavailable|{{.Config.GetOrDefault "maintenance/title" "Title"}}|g' /var/www/html/errors/503.html.tpl
  sed -i 's|The EcoSystem is currently in maintenance mode.|{{.Config.GetOrDefault "maintenance/text" "Text"}}|g' /var/www/html/errors/503.html.tpl

  doguctl template /var/www/html/errors/503.html.tpl /var/www/html/errors/503.html

  doguctl config --remove maintenance || true
}

# Configures the warp menu script as the menu.json gets mounted from a configmap into "/var/www/html/warp/menu"
# instead of "/var/www/html/warp". This is a special constraints when mounting config maps. Mounting the warp menu
# json directly into the warp folder would directly delete other files in the warp folder, including the warp.js script.
function configureWarpMenuJson() {
  log "Configure warp menu..."

  # Replace /warp/menu.json with /warp/menu/menu.json
  sed -i "s|/warp/menu.json|/warp/menu/menu.json|g" /var/www/html/warp/warp.js
}

# Templates the /etc/nginx/include.d/default-dogu.conf.tpl file with doguctl into /etc/nginx/include.d/default-dogu.conf.
#
# Creates a valid location configuration for "/" redirecting to the currently configured default dogu. The config
# redirects to the ces about page if no default dogu is specified.
function configureDefaultDogu() {
  log "Configure default dogu..."

  doguctl template /etc/nginx/include.d/default-dogu.conf.tpl /etc/nginx/include.d/default-dogu.conf
}

# Templates the /etc/nginx/include.d/customhtml.conf.tpl file with doguctl into /etc/nginx/include.d/customhtml.conf.
#
# Creates a new special location for custom content, where the user can deploy his own custom content.
function configureCustomHtmlContent() {
  log "Configure custom content pages..."

  doguctl template /etc/nginx/include.d/customhtml.conf.tpl /etc/nginx/include.d/customhtml.conf
}

# Templates the /etc/nginx/nginx.conf.tpl file with doguctl into /etc/nginx/nginx.conf.
#
# Reads the currently configured log level with doguctl and templates it into the main configuration file.
function configureLogLevel() {
  log "Configure logging..."

  local etcdLogLevel=""
  etcdLogLevel="$(doguctl config logging/root --default "WARN")"
  log "Found etcd log level: ${etcdLogLevel}"

  # The log level is exported for `doguctl template`
  # The format is almost the same, except the case. The etcd-format is all uppercase, the configuration format
  # is all lower case.
  # bashsupport disable=BP2001
  export LOG_LEVEL="${etcdLogLevel,,}"

  log "Set dogu log level to : ${LOG_LEVEL}"
  doguctl template /etc/nginx/nginx.conf.tpl /etc/nginx/nginx.conf
}

# Starts the nginx server.
function startNginx() {
  log "Starting nginx service..."
  exec nginx -c /etc/nginx/nginx.conf -g "daemon off;"
}

# make the script only run when executed, not when sourced from bats tests.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printCloudoguLogo
  configureWarpMenuJson
  configureDefaultDogu
  configureCustomHtmlContent
  configureLogLevel
  configureMaintenanceModeSite
  startNginx
fi
