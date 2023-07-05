#!/usr/bin/env bash

# This function uses () to fork a new process and isolate the environment variables.
# The purpose of forking a new process is to prevent unintended changes to the environment variables used within the function.
# By isolating the variables, we ensure that any modifications made inside the function do not affect the parent process or other functions.
# This helps maintain a clean and predictable environment for the function execution.
function create-apache-vhost (

  local -r _FILENAME=$1
  local -r _NAME=$2

  source ${_FILENAME}

  export ELASTICMS_ADMIN_INSTANCE_NAME="${_NAME}"

  mkdir -p /etc/apache2/conf.d/${_NAME}

  if [ -f /etc/apache2/conf.d/${_NAME}/${_NAME}.env.conf ] ; then
    rm /etc/apache2/conf.d/${_NAME}/${_NAME}.env.conf
  fi

  cat ${_FILENAME} | sed '/^\s*$/d' | grep  -v '^#' | sed "s/\([a-zA-Z0-9_]*\)\=\(.*\)/SetEnv \1 \2/g" >> /etc/apache2/conf.d/${_NAME}/${_NAME}.env.conf

  if [ -f /etc/apache2/conf.d/${_NAME}-vhost.conf ] ; then
    rm /etc/apache2/conf.d/${_NAME}-vhost.conf
  fi

  gomplate \
    -f /usr/local/etc/templates/elasticms-admin.vhost.conf.tmpl \
    -o /etc/apache2/conf.d/${_NAME}-vhost.conf

  # Metrics VHOST

  if [ -z "${EMS_METRIC_ENABLED}" ] || [ "${EMS_METRIC_ENABLED}" != "true" ]; then
    echo -e "  No Prometheus Metrics <VirtualHost> is requiered for [ ${_NAME} ] ElasticMS Admin instance.  Skip ..."
  else

    if [ -f /etc/apache2/conf.d/__metrics.conf ] ; then
      return 0
    fi

    gomplate \
      -d env=${_FILENAME} \
      -f /usr/local/etc/templates/elasticms-admin-metrics.vhost.conf.tmpl \
      -o /etc/apache2/conf.d/__metrics.conf
    
    echo -e "  Apache VirtualHost ( Prometheus Metrics ) configured successfully ..."

  fi

  echo -e "  Apache VirtualHost ( ${SERVER_NAME} ) configured successfully ..."

)

true