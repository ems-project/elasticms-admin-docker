#!/usr/bin/env bash

if [[ ! -z ${METRICS_ENABLED} ]] && [[ ${METRICS_ENABLED,,} = true ]]; then

  echo -e "    Clear Elasticms metrics for [ ${ELASTICMS_INSTANCE_NAME} ] CMS Domain ..."

  ${APP_BIN_DIR}/${ELASTICMS_INSTANCE_NAME} ems:metric:collect --clear

  if [ $? -eq 0 ]; then
    echo -e "    Clear Elasticms metrics for [ ${ELASTICMS_INSTANCE_NAME} ] CMS Domain run successfully ..."
  else
    echo -e "    Warning: something doesn't work with Elasticms metrics clearing !"
  fi

fi