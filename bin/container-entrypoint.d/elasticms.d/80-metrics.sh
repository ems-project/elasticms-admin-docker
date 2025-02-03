#!/usr/bin/env bash

if [[ ! -z ${EMS_METRICS_ENABLED} ]] && [[ ${EMS_METRICS_ENABLED,,} = true ]]; then

  log "INFO" "+ Clear Elasticms metrics for [ ${ELASTICMS_INSTANCE_NAME} ] CMS Domain ..."

  ${APP_BIN_DIR}/${ELASTICMS_INSTANCE_NAME} ems:metric:collect --clear --env=prod

  if [ $? -eq 0 ]; then
    log "ERROR" "! Something doesn't work with Elasticms metrics clearing !"
  fi

fi