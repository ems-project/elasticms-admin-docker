#!/usr/bin/env bash

echo -e "    Running Elasticms assets installation to ${APP_ASSETS_DIR} folder for [ ${ELASTICMS_INSTANCE_NAME} ] CMS Domain ..."

${APP_BIN_DIR}/${ELASTICMS_INSTANCE_NAME} asset:install ${APP_ASSETS_DIR} --symlink --no-interaction --env=prod

if [ $? -eq 0 ]; then
  echo -e "    Elasticms assets installation for [ ${ELASTICMS_INSTANCE_NAME} ] CMS Domain run successfully ..."
else
  echo -e "    Warning: something doesn't work with Elasticms assets installation !"
fi
