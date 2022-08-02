#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

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

# Replace /warp/menu.json with /warp/menu/menu.json
# Menu.json gets mounted from a configmap so other files in /var/www/html/warp would be deleted.
sed -i "s|/warp/menu.json|/warp/menu/menu.json|g" /var/www/html/warp/warp.js

# include default_dogu in default-dogu.conf
echo "[nginx] configure default redirect ..."
doguctl template /etc/nginx/include.d/default-dogu.conf.tpl /etc/nginx/include.d/default-dogu.conf

## configure the access to static html content
#echo "[nginx] configure custom content pages ..."
#doguctl template /etc/nginx/include.d/customhtml.conf.tpl /etc/nginx/include.d/customhtml.conf
#
## render main configuration to include log_level
#echo "[nginx] configure logging ..."
#export_log_level
#doguctl template /etc/nginx/nginx.conf.tpl /etc/nginx/nginx.conf

# Start nginx
echo "[nginx-static] starting nginx service..."
exec /usr/sbin/nginx -c /etc/nginx/nginx.conf -g "daemon off;"
