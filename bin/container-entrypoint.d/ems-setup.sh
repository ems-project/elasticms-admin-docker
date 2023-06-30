#!/usr/bin/env bash
set -eo pipefail

export DEBUG=${DEBUG:-false}
[[ "${DEBUG}" == "true" ]] && set -x

echo -e "\nConfigure ElasticMS Admin Container"

for FILE in $(find /opt/bin/container-entrypoint.d/entrypoint.d -iname \*.sh | sort)
do
  source ${FILE}
done

for FILE in $(find /opt/bin/container-entrypoint.d/elasticms.d -iname \*.sh | sort)
do
  source ${FILE}
done

echo -e "\nElasticMS Admin Container configured succesfully"