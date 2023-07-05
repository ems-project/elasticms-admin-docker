#!/usr/bin/env bash

# This function uses () to fork a new process and isolate the environment variables.
# The purpose of forking a new process is to prevent unintended changes to the environment variables used within the function.
# By isolating the variables, we ensure that any modifications made inside the function do not affect the parent process or other functions.
# This helps maintain a clean and predictable environment for the function execution.
function configure-elasticms-jobs (

  local -r _FILENAME=$1
  local -r _NAME=$2

  source ${_FILENAME}

  export ELASTICMS_ADMIN_INSTANCE_NAME="${_NAME}"

  mkdir -p /etc/supervisord/supervisord.d

  gomplate \
    -d NAME="${_NAME}" \
    -f /usr/local/etc/templates/elasticms-jobs.supervisor-event-listener.ini.tmpl \
    -o /etc/supervisord/supervisord.d/${_NAME}.ini

  mkdir -p /opt/bin/ems-jobs

  gomplate \
    -d NAME="${_NAME}" \
    -f /usr/local/etc/templates/elasticms-jobs.wrapper.script.sh.tmpl \
    -o /opt/bin/ems-jobs/${_NAME}

  chmod a+x /opt/bin/ems-jobs/${_NAME}

  echo -e "  Supervisor Event Listener configured successfully ..."

)

true