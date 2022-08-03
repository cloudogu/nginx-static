#! /bin/bash
# Bind an unbound BATS variables that fail all tests when combined with 'set -o nounset'
export BATS_TEST_START_TIME="0"
export BATSLIB_FILE_PATH_REM=""
export BATSLIB_FILE_PATH_ADD=""

load '/workspace/target/bats_libs/bats-support/load.bash'
load '/workspace/target/bats_libs/bats-assert/load.bash'
load '/workspace/target/bats_libs/bats-mock/load.bash'
load '/workspace/target/bats_libs/bats-file/load.bash'

setup() {
  export STARTUP_DIR=/workspace/resources
  export WORKDIR=/workspace

  # append BATS_TMPDIR before path so that the bash takes our sed mock before the actual sed located in the PATH.
  export PATH="${BATS_TMPDIR}:${PATH}"
}

teardown() {
  unset STARTUP_DIR
  unset WORKDIR
}

@test "printCloudoguLogo - should print the cloudogu logo in ASCI art" {
  # given
  source /workspace/resources/startup.sh

  # when
  run printCloudoguLogo

  # then
  assert_success
  assert_line "                                     ./////,                    "
  assert_line "                                 ./////==//////*                "
  assert_line "                                ////.  ___   ////.              "
  assert_line "                         ,**,. ////  ,////A,  */// ,**,.        "
  assert_line "                    ,/////////////*  */////*  *////////////A    "
  assert_line "                   ////'        \VA.   '|'   .///'       '///*  "
  assert_line "                  *///  .*///*,         |         .*//*,   ///* "
  assert_line "                  (///  (//////)**--_./////_----*//////)   ///) "
  assert_line "                   V///   '°°°°      (/////)      °°°°'   ////  "
  assert_line "                    V/////(////////\. '°°°' ./////////(///(/'   "
  assert_line "                       'V/(/////////////////////////////V'      "
}

@test "log - should log a message with appropriate prefix" {
  # given
  source /workspace/resources/startup.sh

  # when
  run log "Test Message"

  # then
  assert_success
  assert_line "[nginx-static][startup] Test Message"
}

@test "configureWarpMenuJson - should call doguctl to template our file" {
  # given
  source /workspace/resources/startup.sh
  sed() { echo "sed called with params [$*]"; }

  # when
  run configureWarpMenuJson

  # then
  assert_success
  assert_line "[nginx-static][startup] Configure warp menu..."
  assert_line "sed called with params [-i s|/warp/menu.json|/warp/menu/menu.json|g /var/www/html/warp/warp.js]"
}

@test "configureDefaultDogu - should template /etc/nginx/include.d/default-dogu.conf.tpl" {
  # given
  source /workspace/resources/startup.sh
  doguctl() { echo "doguctl called with params [$*]"; }

  # when
  run configureDefaultDogu

  # then
  assert_success
  assert_line "[nginx-static][startup] Configure default dogu..."
  assert_line "doguctl called with params [template /etc/nginx/include.d/default-dogu.conf.tpl /etc/nginx/include.d/default-dogu.conf]"
}

@test "configureCustomHtmlContent - should template /etc/nginx/include.d/customhtml.conf.tpl" {
  # given
  source /workspace/resources/startup.sh
  doguctl() { echo "doguctl called with params [$*]"; }

  # when
  run configureCustomHtmlContent

  # then
  assert_success
  assert_line "[nginx-static][startup] Configure custom content pages..."
  assert_line "doguctl called with params [template /etc/nginx/include.d/customhtml.conf.tpl /etc/nginx/include.d/customhtml.conf]"
}

@test "configureLogLevel - should template /etc/nginx/nginx.conf.tpl with correct log level" {
  # given
  source /workspace/resources/startup.sh
  doguctl() {
    local command="${*}"
    if [ "${command}" == "config logging/root --default WARN" ]; then
      echo "DEBUG"
      return
    fi

    echo "doguctl called with params [$*]"
  }

  # when
  run configureLogLevel

  # then
  assert_success
  assert_line "[nginx-static][startup] Configure logging..."
  assert_line "[nginx-static][startup] Found etcd log level: DEBUG"
  assert_line "[nginx-static][startup] Set dogu log level to : debug"
  assert_line "doguctl called with params [template /etc/nginx/nginx.conf.tpl /etc/nginx/nginx.conf]"
}

@test "startNginx - should start the nginx server" {
  # given
  source /workspace/resources/startup.sh
  exec() {
    echo "exec called with params [$*]"
  }

  # when
  run startNginx

  # then
  assert_success
  assert_line "[nginx-static][startup] Starting nginx service..."
  assert_line "exec called with params [nginx -c /etc/nginx/nginx.conf -g daemon off;]"
}