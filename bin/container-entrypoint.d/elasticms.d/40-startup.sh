#!/usr/bin/env bash

for FILE in ${ELASTICMS_ADMIN_ENV_FILES}; do

  _FILENAME=$(basename "${FILE}")

  echo -e "\n- Setting Up [ ${_FILENAME%.*} ] ElasticMS Admin instance ..."

  create-apache-vhost "${FILE}" "${_FILENAME%.*}"
  create-wrapper-scripts "${FILE}" "${_FILENAME%.*}"

  if [ -z "${JOBS_ENABLED}" ] || [ "${JOBS_ENABLED}" != "true" ]; then
    echo -e "  Use PHP-FPM for running EMS Jobs ..."
  else
    configure-elasticms-jobs "${FILE}" "${_FILENAME%.*}"
  fi

  elasticms-warmup "${FILE}" "${_FILENAME%.*}"

done

true