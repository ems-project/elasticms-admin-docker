#!/usr/bin/env bash
set -eo pipefail

export DEBUG=${DEBUG:-false}
[[ "${DEBUG}" == "true" ]] && set -x

echo -e "\n## —— Configure ElasticMS Admin Container ——————————————————————————————————————"

for FILE in $(find /opt/bin/container-entrypoint.d/entrypoint.d -iname \*.sh | sort)
do
  source ${FILE}
done

for FILE in $(find /opt/bin/container-entrypoint.d/elasticms.d -iname \*.sh | sort)
do
  source ${FILE}
done

echo -e "\n## —— ElasticMS Admin Container configured succesfully —————————————————————————"
echo -e "\n"