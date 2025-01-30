#!/usr/bin/env bash

echo -e "    Configure Apache VirtualHosts ..."

if [[ ! -z ${APACHE_ENABLED} ]] && [[ ${APACHE_ENABLED,,} = true ]]; then

  echo -e "    - Configure [ ${ELASTICMS_INSTANCE_NAME} ] VirtualHost for ElasticMS Admin on [ ${SERVER_NAME} ] ..."

  gomplate -f /app/config/apache2/conf.d/elasticms.conf.gtpl \
           -o /app/etc/apache2/conf.d/${ELASTICMS_INSTANCE_NAME}-app.conf

  cat ${APP_CONFIG_DIR}/${ELASTICMS_INSTANCE_NAME} | sed '/^\s*$/d' | grep  -v '^#' | sed "s/\([a-zA-Z0-9_]*\)\=\(.*\)/        SetEnv \1 \2/g" >> /app/etc/apache2/conf.d/${ELASTICMS_INSTANCE_NAME}-app.env

  if [[ ! -z ${METRICS_ENABLED} ]] && [[ ${METRICS_ENABLED,,} = true ]]; then

    if [ ! -f /app/etc/apache2/conf.d/__metrics.conf ] ; then

      echo -e "    - Configure [ metrics ] VirtualHost for ElasticMS Admin on [ ${METRICS_VHOST_SERVER_NAME} ] ..."

      gomplate -f /app/config/apache2/conf.d/metrics.conf.gtpl \
               -o /app/etc/apache2/conf.d/__metrics.conf

      cat ${APP_CONFIG_DIR}/${ELASTICMS_INSTANCE_NAME} | sed '/^\s*$/d' | grep  -v '^#' | sed "s/\([a-zA-Z0-9_]*\)\=\(.*\)/        SetEnv \1 \2/g" >> /app/etc/apache2/conf.d/__metrics.env

    fi

  fi

fi
