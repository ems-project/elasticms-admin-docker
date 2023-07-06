function configure_database {
  local -r _container_name=${1}

  local -r _DB_DRIVER=${2}
  local -r _DB_ROOT_USER=${3}
  local -r _DB_ROOT_PASSWORD=${4}
  local -r _DB_ROOT_NAME=${5}

  local -r _DB_PORT=${6}
  local -r _DB_HOST=${7}
  local -r _DB_USER=${8}
  local -r _DB_PASSWORD=${9}
  local -r _DB_NAME=${10}
  local -r _DB_SCHEMA=${11}

  if [ ${_DB_DRIVER} = mysql ] ; then
    configure_mysql ${_container_name} ${_DB_ROOT_USER} ${_DB_ROOT_PASSWORD} ${_DB_ROOT_NAME} ${_DB_PORT} ${_DB_HOST} ${_DB_USER} ${_DB_PASSWORD} ${_DB_NAME}
  elif [ ${_DB_DRIVER} = pgsql ] ; then
    configure_pgsql ${_container_name} ${_DB_ROOT_USER} ${_DB_ROOT_PASSWORD} ${_DB_ROOT_NAME} ${_DB_PORT} ${_DB_HOST} ${_DB_USER} ${_DB_PASSWORD} ${_DB_NAME} ${_DB_SCHEMA}
  else
    echo "Driver ${_DB_DRIVER} not supported"
    return -1
  fi;

}

function configure_mysql {
  local -r _container_name=${1}

  local -r _DB_ROOT_USER=${2}
  local -r _DB_ROOT_PASSWORD=${3}
  local -r _DB_ROOT_NAME=${4}

  local -r _DB_PORT=${5}
  local -r _DB_HOST=${6}
  local -r _DB_USER=${7}
  local -r _DB_PASSWORD=${8}
  local -r _DB_NAME=${9}

  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "mysql -u${_DB_ROOT_USER} -p${_DB_ROOT_PASSWORD} -vvv -e \"CREATE DATABASE ${_DB_NAME};\""
  assert_output -l -r "Query OK, .* affected \(.*\)"

  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "mysql -u${_DB_ROOT_USER} -p${_DB_ROOT_PASSWORD} -vvv -e \"CREATE USER '${_DB_USER}'@'%' IDENTIFIED BY '${_DB_PASSWORD}';\""
  assert_output -l -r "Query OK, .* affected \(.*\)"

  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "mysql -u${_DB_ROOT_USER} -p${_DB_ROOT_PASSWORD} -vvv -e \"GRANT ALL PRIVILEGES ON ${_DB_NAME} . * TO '${_DB_USER}'@'%';\""
  assert_output -l -r "Query OK, .* affected \(.*\)"

  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "mysql -u${_DB_ROOT_USER} -p${_DB_ROOT_PASSWORD} -vvv -e \"FLUSH PRIVILEGES;\""
  assert_output -l -r "Query OK, .* affected \(.*\)"
  
}

function configure_pgsql {
  local -r _container_name=${1}

  local -r _DB_ROOT_USER=${2}
  local -r _DB_ROOT_PASSWORD=${3}
  local -r _DB_ROOT_NAME=${4}

  local -r _DB_PORT=${5}
  local -r _DB_HOST=${6}
  local -r _DB_USER=${7}
  local -r _DB_PASSWORD=${8}
  local -r _DB_NAME=${9}
  local -r _DB_SCHEMA=${10}

  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "PGHOST=${_DB_HOST} PGPORT=${_DB_PORT} PGDATABASE=${_DB_ROOT_NAME} PGUSER=${_DB_ROOT_USER} PGPASSWORD=${_DB_ROOT_PASSWORD} psql --command=\"CREATE USER ${_DB_USER} WITH PASSWORD '${_DB_PASSWORD}';\""
  assert_output -l -r "CREATE ROLE"

  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "PGHOST=${_DB_HOST} PGPORT=${_DB_PORT} PGDATABASE=${_DB_ROOT_NAME} PGUSER=${_DB_ROOT_USER} PGPASSWORD=${_DB_ROOT_PASSWORD} psql --command=\"CREATE DATABASE ${_DB_NAME} WITH OWNER ${_DB_USER};\""
  assert_output -l -r "CREATE DATABASE"

  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "PGHOST=${_DB_HOST} PGPORT=${_DB_PORT} PGDATABASE=${_DB_ROOT_NAME} PGUSER=${_DB_ROOT_USER} PGPASSWORD=${_DB_ROOT_PASSWORD} psql --command=\"GRANT ALL PRIVILEGES ON DATABASE ${_DB_NAME} TO ${_DB_USER};\""
  assert_output -l -r "GRANT"

  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "PGHOST=${_DB_HOST} PGPORT=${_DB_PORT} PGDATABASE=${_DB_NAME} PGUSER=${_DB_USER} PGPASSWORD='${_DB_PASSWORD}' psql --command=\"CREATE SCHEMA IF NOT EXISTS ${_DB_SCHEMA} AUTHORIZATION ${_DB_USER};\""
  assert_output -l -r "CREATE SCHEMA"

  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "PGHOST=${_DB_HOST} PGPORT=${_DB_PORT} PGDATABASE=${_DB_NAME} PGUSER=${_DB_USER} PGPASSWORD='${_DB_PASSWORD}' psql --command=\"ALTER USER ${_DB_USER} SET SEARCH_PATH TO ${_DB_SCHEMA};\""
  assert_output -l -r "ALTER ROLE"

}

function provision-volume {

  local -r CONTENT_PATH=${1}
  local -r VOLUME_NAME=${2}
  local -r VOLUME_PATH=${3}

  local STATUS=0

  run ${BATS_CONTAINER_ENGINE} container create --name dummy -v ${VOLUME_NAME}:${VOLUME_PATH} alpine:latest
  assert_output -l -r "^[a-f0-9]{64}$"

  run ${BATS_CONTAINER_ENGINE} cp ${CONTENT_PATH} dummy:${VOLUME_PATH}

  run ${BATS_CONTAINER_ENGINE} rm dummy
  assert_output -l -r "dummy"

}