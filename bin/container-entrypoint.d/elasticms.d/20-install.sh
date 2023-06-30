#!/usr/bin/env bash

echo -e "\n- Install ElasticMS Admin configuration files ..."

if [[ -n "${AWS_S3_CONFIG_BUCKET_NAME}" ]] ; then

  echo -e "  Found AWS_S3_CONFIG_BUCKET_NAME environment variable.  Reading .env files ..."

  export AWS_S3_CONFIG_BUCKET_NAME=${AWS_S3_CONFIG_BUCKET_NAME#s3://}
  list=(`aws s3 ls ${AWS_S3_CONFIG_BUCKET_NAME%/}/ ${AWS_CLI_EXTRA_ARGS} | awk '{print $4}'`)
  for config in ${list[@]};
  do
    echo -e "  Install [ /tmp/${config%.*} ] ElasticMS Admin .env file from S3 Bucket [ $config ] file ..."
    aws s3 cp s3://${AWS_S3_CONFIG_BUCKET_NAME%/}/$config ${AWS_CLI_EXTRA_ARGS} - | envsubst > /tmp/${config%.*}
    ELASTICMS_ADMIN_ENV_FILES_ARR+=" /tmp/${config%.*}"
  done

elif [ "$(ls -A /opt/secrets)" ]; then

  echo -e "  Found '/opt/secrets' folder with files.  Reading .env files ..."
  for file in /opt/secrets/*; do
    filename=$(basename $file)
    envsubst < $file > /tmp/${filename%.*}
    echo "  Install [ /tmp/${filename%.*} ] ElasticMS Admin configuration [ ${filename} ] file from /opt/secrets/ folder ..."
    ELASTICMS_ADMIN_ENV_FILES_ARR+=" /tmp/${filename%.*}"
  done

elif [ "$(ls -A /opt/configs)" ]; then

  echo -e "  Found '/opt/configs' folder with files.  Reading .env files ..."
  for file in /opt/configs/*; do
    filename=$(basename $file)
    envsubst < $file > /tmp/${filename%.*}
    echo -e "  Install [ /tmp/${filename%.*} ] ElasticMS Admin configuration [ ${filename} ] file from /opt/configs/ folder ..."
    ELASTICMS_ADMIN_ENV_FILES_ARR+=" /tmp/${filename%.*}"
  done

else

  env | envsubst > /tmp/default
  echo -e "  Install [ default ] ElasticMS Admin Domain from Environment variables ..."
  ELASTICMS_ADMIN_ENV_FILES_ARR+=" /tmp/default"

fi

export ELASTICMS_ADMIN_ENV_FILES="${ELASTICMS_ADMIN_ENV_FILES_ARR[*]}"

true