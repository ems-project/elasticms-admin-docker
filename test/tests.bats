#!/usr/bin/env bats
load "helpers/tests"
load "helpers/containers"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

export BATS_ROOT_DB_USER="${BATS_ROOT_DB_USER:-root}"
export BATS_ROOT_DB_PASSWORD="${BATS_ROOT_DB_PASSWORD:-password}"
export BATS_ROOT_DB_NAME="${BATS_ROOT_DB_NAME:-root}"

export BATS_DB_DRIVER="${BATS_DB_DRIVER:-pgsql}"
export BATS_DB_HOST="${BATS_DB_HOST:-postgresql}"
export BATS_DB_PORT="${BATS_DB_PORT:-5432}"
export BATS_DB_USER="${BATS_DB_USER:-example_adm}"
export BATS_DB_PASSWORD="${BATS_DB_PASSWORD:-abcd@.<efgh>.}"
export BATS_DB_NAME="${BATS_DB_NAME:-example}"

export BATS_REDIS_HOST="${BATS_REDIS_HOST:-redis}"
export BATS_REDIS_PORT="${BATS_REDIS_PORT:-6379}"

export BATS_JOBS_ENABLED="${BATS_JOBS_ENABLED:-true}"
export BATS_METRICS_ENABLED="${BATS_METRICS_ENABLED:-true}"

export BATS_S3_ELASTICMS_CONFIG_BUCKET_NAME="ems-config/demo/config/elasticms"
export BATS_S3_SKELETON_CONFIG_BUCKET_NAME="ems-config/demo/config/skeleton"
export BATS_S3_STORAGE_BUCKET_NAME="demo-ems-storage"
export BATS_S3_ENDPOINT_URL="http://localhost:19000"
export BATS_S3_ACCESS_KEY_ID="mock"
export BATS_S3_SECRET_ACCESS_KEY="SecretAccessKey"
export BATS_S3_DEFAULT_REGION="us-east-1"

export AWS_ACCESS_KEY_ID="${BATS_S3_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${BATS_S3_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION="${BATS_S3_DEFAULT_REGION}"

export BATS_PHP_FPM_MAX_CHILDREN="${BATS_PHP_FPM_MAX_CHILDREN:-4}"
export BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES="${BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES:-128}"
export BATS_CONTAINER_HEAP_PERCENT="${BATS_CONTAINER_HEAP_PERCENT:-0.80}"

export BATS_ELASTICMS_ADMIN_USERNAME="demo-bats"
export BATS_ELASTICMS_ADMIN_PASSWORD="bats"
export BATS_ELASTICMS_ADMIN_EMAIL="demo.admin.s3.bats@example.com"
export BATS_ELASTICMS_ADMIN_ENVIRONMENT="demo-dev"

export BATS_ELASTICMS_SKELETON_ADMIN_URL="http://demo-admin"
export BATS_ELASTICMS_SKELETON_BACKEND_URL="http://demo-admin-dev:9000"
export BATS_ELASTICMS_SKELETON_ENVIRONMENT="demo-preview-dev"

export BATS_STORAGE_SERVICE_NAME="postgresql"

export BATS_EMS_VERSION="${EMS_VERSION:-5.x}"
export BATS_DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-docker.io/elasticms/admin:rc}"

export BATS_CONTAINER_ENGINE="${CONTAINER_ENGINE:-podman}"
export BATS_CONTAINER_COMPOSE_ENGINE="${BATS_CONTAINER_ENGINE} compose"
export BATS_CONTAINER_NETWORK_NAME="${CONTAINER_NETWORK_NAME:-docker_default}"

@test "[$TEST_FILE] Prepare Skeleton [$BATS_EMS_VERSION]." {

  run git clone -b ${BATS_EMS_VERSION} git@github.com:ems-project/elasticms-demo.git ${BATS_TEST_DIRNAME%/}/demo
  run mkdir -p ${BATS_TEST_DIRNAME%/}/demo/dist
  run npm install --save-dev webpack --prefix ${BATS_TEST_DIRNAME%/}/demo ${BATS_TEST_DIRNAME%/}/demo
  run npm run --prefix ${BATS_TEST_DIRNAME%/}/demo prod
  run chmod 777 ${BATS_TEST_DIRNAME%/}/demo/skeleton

}

@test "[$TEST_FILE] Starting Services (PostgreSQL, Elasticsearch, Redis, Minio, Tika)." {

  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.yml up -d postgresql es01 es02 es03 redis tika minio
  container_wait_for_command postgresql "pg_isready -U ${BATS_ROOT_DB_USER}" "120" "/var/run/postgresql:5432 - accepting connection"
  container_wait_for_log es01 120 ".*\"type\": \"server\", \"timestamp\": \".*\", \"level\": \".*\", \"component\": \".*\", \"cluster.name\": \".*\", \"node.name\": \".*\", \"message\": \"started\".*"
  container_wait_for_log es02 120 ".*\"type\": \"server\", \"timestamp\": \".*\", \"level\": \".*\", \"component\": \".*\", \"cluster.name\": \".*\", \"node.name\": \".*\", \"message\": \"started\".*"
  container_wait_for_log es03 120 ".*\"type\": \"server\", \"timestamp\": \".*\", \"level\": \".*\", \"component\": \".*\", \"cluster.name\": \".*\", \"node.name\": \".*\", \"message\": \"started\".*"
  container_wait_for_log redis 240 "Ready to accept connections"
  container_wait_for_healthy minio 120
  container_wait_for_healthy tika 120

}

@test "[$TEST_FILE] Create Configuration S3 Bucket." {

  export BATS_S3_ENDPOINT_URL=http://$(container_ip minio):9000

  run ${BATS_CONTAINER_ENGINE} run --rm -t --network ${BATS_CONTAINER_NETWORK_NAME} \
                      -e AWS_ACCESS_KEY_ID="${BATS_S3_ACCESS_KEY_ID}" \
                      -e AWS_SECRET_ACCESS_KEY="${BATS_S3_SECRET_ACCESS_KEY}" \
                      -e AWS_DEFAULT_REGION="${BATS_S3_DEFAULT_REGION}" \
      docker.io/amazon/aws-cli:2.11.22 s3 mb s3://${BATS_S3_ELASTICMS_CONFIG_BUCKET_NAME%%/*} --endpoint-url ${BATS_S3_ENDPOINT_URL}

  assert_output -l -r "make_bucket: ${BATS_S3_ELASTICMS_CONFIG_BUCKET_NAME%%/*}"

}

@test "[$TEST_FILE] Create Storage S3 Bucket." {

  export BATS_S3_ENDPOINT_URL=http://$(container_ip minio):9000

  run ${BATS_CONTAINER_ENGINE} run --rm -t --network ${BATS_CONTAINER_NETWORK_NAME} \
                      -e AWS_ACCESS_KEY_ID="${BATS_S3_ACCESS_KEY_ID}" \
                      -e AWS_SECRET_ACCESS_KEY="${BATS_S3_SECRET_ACCESS_KEY}" \
                      -e AWS_DEFAULT_REGION="${BATS_S3_DEFAULT_REGION}" \
      docker.io/amazon/aws-cli:2.11.22 s3 mb s3://${BATS_S3_STORAGE_BUCKET_NAME%%/*} --endpoint-url ${BATS_S3_ENDPOINT_URL}

  assert_output -l -r "make_bucket: ${BATS_S3_STORAGE_BUCKET_NAME%%/*}"

}

@test "[$TEST_FILE] Configure Database." {

  configure_database ${BATS_STORAGE_SERVICE_NAME} ${BATS_DB_DRIVER} ${BATS_ROOT_DB_USER} ${BATS_ROOT_DB_PASSWORD} ${BATS_ROOT_DB_NAME} ${BATS_DB_PORT} ${BATS_DB_HOST} ${BATS_DB_USER} ${BATS_DB_PASSWORD} ${BATS_DB_NAME}

}

@test "[$TEST_FILE] Loading Elasticms Config files in Configuration S3 Bucket." {

  # TODO : update demo project to use more env vars in config file and use theses here (instead of manage own config files)
  for file in ${BATS_TEST_DIRNAME%/}/configs/elasticms/*.env ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    copy_to_s3bucket $file ${BATS_S3_ELASTICMS_CONFIG_BUCKET_NAME%/}/ ${BATS_S3_ENDPOINT_URL}

  done
}

@test "[$TEST_FILE] Loading Skeleton Config files in Configuration S3 Bucket." {

  # TODO : update demo project to use more env vars in config file and use theses here (instead of manage own config files)
  for file in ${BATS_TEST_DIRNAME%/}/configs/skeleton/*.env ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    copy_to_s3bucket $file ${BATS_S3_SKELETON_CONFIG_BUCKET_NAME%/}/ ${BATS_S3_ENDPOINT_URL}

  done
}

@test "[$TEST_FILE] Starting Elasticms." {
  export BATS_ES_LOCAL_ENDPOINT_URL=http://$(container_ip es01):9200
  export BATS_S3_ENDPOINT_URL=http://$(container_ip minio):9000
  export BATS_TIKA_LOCAL_ENDPOINT_URL=http://$(container_ip tika):9998
  export BATS_REDIS_HOST=$(container_ip redis)

  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.yml up -d elasticms

}

@test "[$TEST_FILE] Check Elasticms startup messages in container logs." {

  for file in ${BATS_TEST_DIRNAME%/}/configs/elasticms/*.env ; do
    _basename=$(basename $file)
    _name=${_basename%.*}
    container_wait_for_log ems 60 "Install \[ ${_name} \] CMS Domain from S3 Bucket \[ ${_basename} \] file successfully ..."
    container_wait_for_log ems 60 "Doctrine database migration for \[ ${_name} \] CMS Domain run successfully ..."
    container_wait_for_log ems 60 "Elasticms assets installation for \[ ${_name} \] CMS Domain run successfully ..."
    container_wait_for_log ems 60 "Elasticms warming up for \[ ${_name} \] CMS Domain run successfully ..."
  done

  container_wait_for_log ems 60 "NOTICE: ready to handle connections"
  container_wait_for_log ems 60 "AH00292: Apache/.* \(Unix\) OpenSSL/.* configured -- resuming normal operations"

}

@test "[$TEST_FILE] Starting Skeleton." {
  export BATS_ES_LOCAL_ENDPOINT_URL=http://$(container_ip es01):9200
  export BATS_S3_ENDPOINT_URL=http://$(container_ip minio):9000
  export BATS_TIKA_LOCAL_ENDPOINT_URL=http://$(container_ip tika):9998
  export BATS_REDIS_HOST=$(container_ip redis)

  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.yml up -d emsch

}

@test "[$TEST_FILE] Check Skeleton startup messages in containers logs." {
  for file in ${BATS_TEST_DIRNAME%/}/configs/skeleton/*.env ; do
    _basename=$(basename $file)
    _name=${_basename%.*}
    container_wait_for_log emsch 15 "Install \[ ${_name} \] Skeleton Domain from S3 Bucket \[ ${_basename} \] file successfully ..."
    container_wait_for_log emsch 15 "Elasticms assets installation for \[ ${_name} \] Skeleton Domain run successfully ..."
    container_wait_for_log emsch 15 "Elasticms warming up for \[ ${_name} \] Skeleton Domain run successfully ..."
  done

  container_wait_for_log emsch 15 "NOTICE: ready to handle connections"
  container_wait_for_log emsch 15 "AH00292: Apache/.* \(Unix\) OpenSSL/.* configured -- resuming normal operations"
}

@test "[$TEST_FILE] Create Elasticms Super Admin user." {

  run ${BATS_CONTAINER_ENGINE} exec ems sh -c "/opt/bin/${BATS_ELASTICMS_ADMIN_ENVIRONMENT} emsco:user:create --super-admin --no-debug ${BATS_ELASTICMS_ADMIN_USERNAME} ${BATS_ELASTICMS_ADMIN_EMAIL} ${BATS_ELASTICMS_ADMIN_PASSWORD}"
  assert_output -r ".*\[OK\] Created user \"${BATS_ELASTICMS_ADMIN_USERNAME}\""

  run ${BATS_CONTAINER_ENGINE} exec ems sh -c "/opt/bin/${BATS_ELASTICMS_ADMIN_ENVIRONMENT} emsco:user:promote --no-debug ${BATS_ELASTICMS_ADMIN_USERNAME} ROLE_API"
  assert_output -r ".*\[OK\] Role \"ROLE_API\" has been added to user \"${BATS_ELASTICMS_ADMIN_USERNAME}\".*"

  run ${BATS_CONTAINER_ENGINE} exec ems sh -c "/opt/bin/${BATS_ELASTICMS_ADMIN_ENVIRONMENT} emsco:user:promote --no-debug ${BATS_ELASTICMS_ADMIN_USERNAME} ROLE_COPY_PASTE"
  assert_output -r ".*\[OK\] Role \"ROLE_COPY_PASTE\" has been added to user \"${BATS_ELASTICMS_ADMIN_USERNAME}\".*"

  run ${BATS_CONTAINER_ENGINE} exec ems sh -c "/opt/bin/${BATS_ELASTICMS_ADMIN_ENVIRONMENT} emsco:user:promote --no-debug ${BATS_ELASTICMS_ADMIN_USERNAME} ROLE_ALLOW_ALIGN"
  assert_output -r ".*\[OK\] Role \"ROLE_ALLOW_ALIGN\" has been added to user \"${BATS_ELASTICMS_ADMIN_USERNAME}\".*"

  run ${BATS_CONTAINER_ENGINE} exec ems sh -c "/opt/bin/${BATS_ELASTICMS_ADMIN_ENVIRONMENT} emsco:user:promote --no-debug ${BATS_ELASTICMS_ADMIN_USERNAME} ROLE_FORM_CRM"
  assert_output -r ".*\[OK\] Role \"ROLE_FORM_CRM\" has been added to user \"${BATS_ELASTICMS_ADMIN_USERNAME}\".*"

  run ${BATS_CONTAINER_ENGINE} exec ems sh -c "/opt/bin/${BATS_ELASTICMS_ADMIN_ENVIRONMENT} emsco:user:promote --no-debug ${BATS_ELASTICMS_ADMIN_USERNAME} ROLE_TASK_MANAGER"
  assert_output -r ".*\[OK\] Role \"ROLE_TASK_MANAGER\" has been added to user \"${BATS_ELASTICMS_ADMIN_USERNAME}\".*"

}

@test "[$TEST_FILE] Login to Elasticms for admin." {

  run ${BATS_CONTAINER_ENGINE} exec ems ${BATS_ELASTICMS_ADMIN_ENVIRONMENT} ems:admin:login --no-debug ${BATS_ELASTICMS_SKELETON_BACKEND_URL} --username=${BATS_ELASTICMS_ADMIN_USERNAME} --password=${BATS_ELASTICMS_ADMIN_PASSWORD}
  assert_output -r ".*\[OK\] Welcome ${BATS_ELASTICMS_ADMIN_USERNAME} on ${BATS_ELASTICMS_SKELETON_BACKEND_URL}"

}

@test "[$TEST_FILE] Restore elasticms configuration" {

  run ${BATS_CONTAINER_ENGINE} exec ems ${BATS_ELASTICMS_ADMIN_ENVIRONMENT} ems:admin:restore --no-debug --configs --configs-folder=/opt/src/configs/admin --force

}

@test "[$TEST_FILE] Activate Elasticms content types." {

  run ${BATS_CONTAINER_ENGINE} exec ems ${BATS_ELASTICMS_ADMIN_ENVIRONMENT} ems:contenttype:activate --all --force

}

@test "[$TEST_FILE] Rebuild Elasticms Environments." {

  envs=(`${BATS_CONTAINER_ENGINE} exec ems ${BATS_ELASTICMS_ADMIN_ENVIRONMENT} ems:environment:list --no-debug`)

  for e in ${envs[@]}; do
    run ${BATS_CONTAINER_ENGINE} exec ems ${BATS_ELASTICMS_ADMIN_ENVIRONMENT} ems:environment:rebuild ${e} --no-debug --yellow-ok
    assert_output -r "The alias .* is now point to .*"
  done

}

@test "[$TEST_FILE] Restore elasticms documents" {

  run ${BATS_CONTAINER_ENGINE} exec ems ${BATS_ELASTICMS_ADMIN_ENVIRONMENT} ems:admin:restore --no-debug --documents --documents-folder=/opt/src/configs/document --force

}

@test "[$TEST_FILE] Login to Elasticms for web." {

  run ${BATS_CONTAINER_ENGINE} exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} emsch:local:login ${BATS_ELASTICMS_ADMIN_USERNAME} ${BATS_ELASTICMS_ADMIN_PASSWORD}
  assert_output -r ".*\[OK\] Welcome ${BATS_ELASTICMS_ADMIN_USERNAME} on ${BATS_ELASTICMS_SKELETON_BACKEND_URL}"

}

@test "[$TEST_FILE] Upload web assets." {

  run ${BATS_CONTAINER_ENGINE} exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} emsch:local:upload --filename=/opt/src/local/skeleton/template/asset_hash.twig
  assert_output -r ".*\[OK\] Assets .* have been uploaded"

}

@test "[$TEST_FILE] Push templates, routes and translations." {

  run ${BATS_CONTAINER_ENGINE} exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} emsch:local:push --force

  # Missing message when action is done (with success or not)
  # assert_output -r ""

}

@test "[$TEST_FILE] Align live." {

  run ${BATS_CONTAINER_ENGINE} exec ems ${BATS_ELASTICMS_ADMIN_ENVIRONMENT} ems:environment:align preview live --force --no-debug
  assert_output -r ".*\[OK\] Environments preview -> live were aligned.*"

}

@test "[$TEST_FILE] Check for Elasticms Default Index page response code 200" {

  retry 12 5 curl_container ems :9000/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'

}

@test "[$TEST_FILE] Check for Elasticms status page response code 200 for all configured domains" {

  for file in ${BATS_TEST_DIRNAME%/}/configs/elasticms/*.env ; do

    _basename=$(basename $file)
    _name=${_basename%.*}

    envsubst < $file > /tmp/$_name
    source /tmp/$_name

    retry 12 5 curl_container ems :9000/status -H "Host: ${SERVER_NAME}" -s -w %{http_code} -o /dev/null
    assert_output -l 0 $'200'

    retry 12 5 curl_container ems :9000/health_check.json -H "Host: ${SERVER_NAME}" -s -w %{http_code} -o /dev/null
    assert_output -l 0 $'200'

    rm /tmp/$_name

  done

}

@test "[$TEST_FILE] Check for Elasticms metrics page response code 200 for all configured domains" {

  for file in ${BATS_TEST_DIRNAME%/}/configs/elasticms/*.env ; do

    _basename=$(basename $file)
    _name=${_basename%.*}

    envsubst < $file > /tmp/$_name
    source /tmp/$_name

    retry 12 5 curl_container ems :9090/metrics -H "Host: ${SERVER_NAME}:9090" -s -w %{http_code} -o /dev/null
    assert_output -l 0 $'200'

    rm /tmp/$_name

  done

}

@test "[$TEST_FILE] Check for Monitoring /real-time-status page response code 200" {

  retry 12 5 curl_container ems :9000/real-time-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'

}

@test "[$TEST_FILE] Check for Monitoring /status page response code 200" {

  retry 12 5 curl_container ems :9000/status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'

}

@test "[$TEST_FILE] Check for Monitoring /server-status page response code 200" {

  retry 12 5 curl_container ems :9000/server-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'

}

@test "[$TEST_FILE] Stop all and delete test containers" {
  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.yml down -v
}
