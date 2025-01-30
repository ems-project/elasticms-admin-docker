#!/usr/bin/env bash

echo -e "    Configure ElasticMS Admin Jobs ..."

if [[ ! -z ${JOBS_ENABLED} ]] && [[ ${JOBS_ENABLED,,} = true ]]; then

  echo -e "    > Use Supervisor for running ElasticMS Admin Jobs ..."

  gomplate -f /app/config/supervisor/eventlistener.ini.gtpl \
           -o /app/etc/supervisor.d/${ELASTICMS_INSTANCE_NAME}

  gomplate -f /app/config/sbin/ems-job-run.sh.gtpl \
           -o ${APP_BIN_DIR}/ems-jobs/${ELASTICMS_INSTANCE_NAME}

  chmod a+x ${APP_BIN_DIR}/ems-jobs/${ELASTICMS_INSTANCE_NAME}

else

  echo -e "    > Use PHP-FPM for running ElasticMS Admin Jobs ..."

fi
