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
# Menu.json gets mounted from a configmap so other files in /usr/share/nginx/html/warp would be deleted.
sed -i "s|/warp/menu.json|/warp/menu/menu.json|g" /usr/share/nginx/html/warp/warp.js

# Start nginx
echo "[k8s-static-webserver] starting nginx service..."
exec /usr/sbin/nginx -c /etc/nginx/nginx.conf -g "daemon off;"
