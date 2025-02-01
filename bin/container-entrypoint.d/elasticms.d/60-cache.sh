#!/usr/bin/env bash

echo -e "    Running Elasticms cache warming up for [ ${ELASTICMS_INSTANCE_NAME} ] CMS Domain ..."

${APP_BIN_DIR}/${ELASTICMS_INSTANCE_NAME} cache:warm --no-interaction --env=prod

if [ $? -eq 0 ]; then
  echo -e "    Elasticms warming up for [ ${ELASTICMS_INSTANCE_NAME} ] CMS Domain run successfully ..."
else
  echo -e "    Warning: something doesn't work with Elasticms cache warming up !"
fi