#!/usr/bin/env bash

export APP_BIN_DIR="/app/sbin"
export APP_SRC_DIR="/app/src/elasticms"
export APP_TMP_DIR="${TMPDIR}"

export APP_CONFIG_DIR="${APP_TMP_DIR}/elasticms.d"
export APP_LOG_DIR="/app/var/log/elasticms"

APP_CACHE_DIR_DEFAULT="/app/var/cache/elasticms"
export APP_CACHE_DIR=${APP_CACHE_DIR:-"${APP_CACHE_DIR_DEFAULT}"}
true
