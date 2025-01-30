#!/usr/bin/env bash
set -eo pipefail

echo -e "\n    Configure ElasticMS Admin Container ...\n"

for I in $(find ${APP_CONFIG_DIR}/* | sort)
do

  for FILE in $(find /app/bin/container-entrypoint.d/elasticms.d -iname \*.sh | sort)
  do
    ELASTICMS_INSTANCE_NAME=$(basename "$I" .${I##*.}) \
    ELASTICMS_INSTANCE_CONFIG_FILE=${I} \
    source ${FILE}
  done

done

echo -e "\n    ElasticMS Admin Container configured succesfully ...\n"
