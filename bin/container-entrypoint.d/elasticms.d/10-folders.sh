#!/usr/bin/env bash

echo -e "    Create required folders ..."

OUTDIR="${APP_BIN_DIR}/ems-jobs ${APP_CONFIG_DIR} ${APP_LOG_DIR} ${APP_CACHE_DIR}"

mkdir -p $OUTDIR
