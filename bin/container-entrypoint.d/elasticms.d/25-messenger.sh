#!/usr/bin/env bash

if [[ ! -z ${MESSENGER_ENABLED} ]] && [[ ${MESSENGER_ENABLED,,} = true ]]; then

  log "INFO" "| Configure Supervisor for running ElasticMS Sync & Queued Message Handling ..."

  gomplate -f /app/config/supervisor/messenger-consume.ini.gtpl \
           -o /app/etc/supervisor.d/${ELASTICMS_INSTANCE_NAME}-messenger-consume.ini

fi
