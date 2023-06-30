#!/usr/bin/env bash

echo -e "\n- Warming Up ElasticMS Admin ..."

# This function uses () to fork a new process and isolate the environment variables.
# The purpose of forking a new process is to prevent unintended changes to the environment variables used within the function.
# By isolating the variables, we ensure that any modifications made inside the function do not affect the parent process or other functions.
# This helps maintain a clean and predictable environment for the function execution.
function elasticms-warmup (

  local -r _FILENAME=$1
  local -r _NAME=$2

  source ${_FILENAME}

  export ELASTICMS_ADMIN_INSTANCE_NAME="${_NAME}"

  echo -e "\n  Warming Up ElasticMS Admin instance [ ${_NAME} ] ..."

  if [[ "$DB_DRIVER" =~ ^.*pgsql$ ]]; then
    if [[ "$DB_USER" =~ ^.*_(chg)$ ]]; then
      echo -e "\n  Call start_dbcr() Postgres procedure [ ${_NAME} ] ..."
      psql postgresql://${DB_USER}:$(urlencode.py $DB_PASSWORD)@${DB_HOST//,/:${DB_PORT},}:${DB_PORT}/${DB_NAME}?connect_timeout=${DB_CONNECTION_TIMEOUT:-30} -c 'select * from start_dbcr();'
    fi
  fi

  echo -e "\n  Running Doctrine database migration (sync-metadata-storage) ..."
  /opt/bin/${_NAME} doctrine:migrations:sync-metadata-storage --no-interaction --env=prod
  if [ $? -eq 0 ]; then
    echo -e "  Doctrine sync metadata storage run successfully ..."
  else
    echo -e "  Warning: something doesn't work with doctrine sync metadata  !"
  fi

  echo -e "\n  Running Doctrine database migration ..."
  /opt/bin/${_NAME} doctrine:migrations:migrate --no-interaction --env=prod
  if [ $? -eq 0 ]; then
    echo -e "  Doctrine database migration run successfully for ElasticMS Admin instance [ ${_NAME} ] ..."
  else
    echo -e "  Warning: something doesn't work with Doctrine database migration !"
  fi

  if [[ "$DB_DRIVER" =~ ^.*pgsql$ ]]; then
    if [[ "$DB_USER" =~ ^.*_(chg)$ ]]; then
      echo -e "  Call stop_dbcr() Postgres procedure ..."
      psql postgresql://${DB_USER}:$(urlencode.py $DB_PASSWORD)@${DB_HOST//,/:${DB_PORT},}:${DB_PORT}/${DB_NAME}?connect_timeout=${DB_CONNECTION_TIMEOUT:-30} -c 'select * from stop_dbcr();'
    fi
  fi

  echo -e "\n  Running Elasticms assets installation to /opt/src/public folder ..."
  /opt/bin/${_NAME} asset:install /opt/src/public --symlink --no-interaction --env=prod
  if [ $? -eq 0 ]; then
    echo -e "  Elasticms assets installation run successfully for ElasticMS Admin instance [ ${_NAME} ] ..."
  else
    echo -e "  Warning: something doesn't work with Elasticms assets installation !"
  fi

  echo -e "\n  Running Elasticms cache warming up ..."
  /opt/bin/${_NAME} cache:warm --no-interaction --env=prod
  if [ $? -eq 0 ]; then
    echo -e "  Elasticms warming up run successfully for ElasticMS Admin instance [ ${_NAME} ] ..."
  else
    echo -e "  Warning: something doesn't work with Elasticms cache warming up !"
  fi

  if [[ ! -z ${EMS_METRIC_ENABLED} ]] && [[ ${EMS_METRIC_ENABLED,,} = true ]]; then
    echo -e "\n  [ ${_NAME} ] Clear Elasticms metrics ..."
    /opt/bin/${_NAME} ems:metric:collect --clear
    if [ $? -eq 0 ]; then
      echo -e "  Clear Elasticms metrics run successfully ..."
    else
      echo -e "  Warning: something doesn't work with Elasticms metrics clearing !"
    fi
  fi

)

for FILE in ${ELASTICMS_ADMIN_ENV_FILES}; do

  _FILENAME=$(basename "${FILE}")
  elasticms-warmup "${FILE}" "${_FILENAME%.*}"

done

true