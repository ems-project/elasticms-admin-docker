#!/usr/bin/env bash

echo -e "\n- Create ElasticMS Admin required folders ..."

if [ ! -z "${STORAGE_FOLDER}" ]; then

  if [ ! -d "${STORAGE_FOLDER}" ]; then
    echo -e "  Try to create ${STORAGE_FOLDER} missing folder."
    mkdir -p ${STORAGE_FOLDER}
  fi

else

  if [ ! -d /var/lib/ems/assets ]; then
    echo -e "  Try to create (default) /var/lib/ems/assets missing folder."
    mkdir -p /var/lib/ems/assets
  fi

fi

if [ ! -z "${EMS_UPLOAD_FOLDER}" ]; then

  if [ ! -d "${EMS_UPLOAD_FOLDER}" ]; then
    echo -e "  Try to create ${EMS_UPLOAD_FOLDER} missing folder."
    mkdir -p ${EMS_UPLOAD_FOLDER}
  fi

else

  if [ ! -d /var/lib/ems/uploads ]; then
    echo -e "  Try to create (default) /var/lib/ems/uploads missing folder."
    mkdir -p /var/lib/ems/uploads
  fi

fi

if [ ! -z "${EMS_DUMPS_FOLDER}" ]; then

  if [ ! -d "${EMS_DUMPS_FOLDER}" ]; then
    echo -e "  Try to create ${EMS_DUMPS_FOLDER} missing folder."
    mkdir -p ${EMS_DUMPS_FOLDER}
  fi

else

  if [ ! -d /var/lib/ems/dumps ]; then
    echo -e "  Try to create (default) /var/lib/ems/dumps missing folder."
    mkdir -p /var/lib/ems/dumps
  fi

fi

true