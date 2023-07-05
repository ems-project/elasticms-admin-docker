#!/usr/bin/env bash

# This function uses () to fork a new process and isolate the environment variables.
# The purpose of forking a new process is to prevent unintended changes to the environment variables used within the function.
# By isolating the variables, we ensure that any modifications made inside the function do not affect the parent process or other functions.
# This helps maintain a clean and predictable environment for the function execution.
function create-wrapper-scripts (

  local -r _FILENAME=$1
  local -r _NAME=$2

  source ${_FILENAME}

  export ELASTICMS_ADMIN_INSTANCE_NAME="${_NAME}"

  gomplate \
    -f /usr/local/etc/templates/elasticms-admin.wrapper.script.sh.tmpl \
    -o /opt/bin/${_NAME}

  chmod a+x /opt/bin/${_NAME}

  echo -e "  Wrapper script created successfully ..."

)

true