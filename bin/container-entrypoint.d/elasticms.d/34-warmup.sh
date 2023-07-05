#!/usr/bin/env bash

function elasticms-command {

  local -r _EMS_INSTANCE=$1
  local -r _EMS_COMMAND=$2

  export LOG_TMP_FILE=$(mktemp)

  echo -e "\n  Running command: '/opt/bin/${_EMS_INSTANCE} ${_EMS_COMMAND}' ..."

  /opt/bin/${_EMS_INSTANCE} ${_EMS_COMMAND} > "${LOG_TMP_FILE}" 2>&1

  if [ $? -eq 0 ]; then
    echo -e "  Command '/opt/bin/${_EMS_INSTANCE} ${_EMS_COMMAND}' executed successfully."
    [[ "${APP_ENV}" == "dev" ]] && displayLog
  else
    echo -e "  Warning: something doesn't work with command: '/opt/bin/${_EMS_INSTANCE} ${_EMS_COMMAND}' !"
    echo -e "  -- OUTPUT COMMAND --"
    displayLog
  fi

  rm ${LOG_TMP_FILE}

}

function change-database-state {

  local -r _ACTION=$1
  local _STORED_PROCEDURE_QUERY="select * from ${_ACTION}_dbcr();"

  export LOG_TMP_FILE=$(mktemp)

  psql postgresql://${DB_USER}:$(urlencode.py $DB_PASSWORD)@${DB_HOST//,/:${DB_PORT},}:${DB_PORT}/${DB_NAME}?connect_timeout=${DB_CONNECTION_TIMEOUT:-30} -c "${_STORED_PROCEDURE_QUERY}" > "${LOG_TMP_FILE}" 2>&1

  if [ $? -eq 0 ]; then
    echo -e "  Postgres procedure ${_ACTION}_dbcr() executed successfully."
    [[ "${APP_ENV}" == "dev" ]] && displayLog
  else
    echo -e "  Warning: something doesn't work with Postgres procedure: '${_ACTION}_dbcr()' !"
    echo -e "  -- OUTPUT COMMAND --"
    displayLog
  fi

  rm ${LOG_TMP_FILE}

}

# This function uses () to fork a new process and isolate the environment variables.
# The purpose of forking a new process is to prevent unintended changes to the environment variables used within the function.
# By isolating the variables, we ensure that any modifications made inside the function do not affect the parent process or other functions.
# This helps maintain a clean and predictable environment for the function execution.
function elasticms-warmup (

  local -r _FILENAME=$1
  local -r _NAME=$2

  source ${_FILENAME}

  export ELASTICMS_ADMIN_INSTANCE_NAME="${_NAME}"

  if [[ "$DB_DRIVER" =~ ^.*pgsql$ ]]; then
    if [[ "$DB_USER" =~ ^.*_(chg)$ ]]; then
      change-database-state "start"
    fi
  fi

  elasticms-command "${ELASTICMS_ADMIN_INSTANCE_NAME}" "doctrine:migrations:sync-metadata-storage --no-interaction --env=prod"
  elasticms-command "${ELASTICMS_ADMIN_INSTANCE_NAME}" "doctrine:migrations:migrate --no-interaction --env=prod"

  if [[ "$DB_DRIVER" =~ ^.*pgsql$ ]]; then
    if [[ "$DB_USER" =~ ^.*_(chg)$ ]]; then
      change-database-state "stop"
    fi
  fi

  elasticms-command "${ELASTICMS_ADMIN_INSTANCE_NAME}" "asset:install /opt/src/public --symlink --no-interaction --env=prod"
  elasticms-command "${ELASTICMS_ADMIN_INSTANCE_NAME}" "cache:warm --no-interaction --env=prod"

  if [[ ! -z ${EMS_METRIC_ENABLED} ]] && [[ ${EMS_METRIC_ENABLED,,} = true ]]; then
    elasticms-command "${ELASTICMS_ADMIN_INSTANCE_NAME}" "ems:metric:collect --clear"
  fi

)

true