#!/usr/bin/env bash

echo -e "    Create ElasticMS Admin Shell script in ${APP_BIN_DIR} ..."

gomplate -f /app/config/sbin/instance.sh.gtpl \
         -o ${APP_BIN_DIR}/${ELASTICMS_INSTANCE_NAME}

chmod a+x ${APP_BIN_DIR}/${ELASTICMS_INSTANCE_NAME}
