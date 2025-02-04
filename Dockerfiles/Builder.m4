ENV ELASTICMS_VERSION=${VERSION_ARG:-6.0.0} \
    ELASTICMS_DOWNLOAD_URL="https://github.com/ems-project/elasticms-admin/archive" \
    APP_DISABLE_DOTENV=true \
    EMSCO_TIKA_SERVER=http://null \
    MAILER_URL=smtp://null

WORKDIR /app/src/elasticms

RUN set -x ; \
    mkdir -p /app/src/elasticms ; \
    curl -sSfLk ${ELASTICMS_DOWNLOAD_URL}/${ELASTICMS_VERSION}.tar.gz \
       | tar -xzC /app/src/elasticms --strip-components=1 ; \
    COMPOSER_MEMORY_LIMIT=-1 composer -vvv install --no-interaction --no-suggest --no-scripts --working-dir /app/src/elasticms -o ; \
    npm install --prefix /app/src/elasticms/vendor/elasticms/admin-ui-bundle/assets ; \
    npm --prefix /app/src/elasticms/vendor/elasticms/admin-ui-bundle/assets run build ; \
    rm -rf /app/src/elasticms/vendor/elasticms/admin-ui-bundle/assets/node_modules ; \
    \
    php /app/src/elasticms/bin/console assets:install /app/src/elasticms/public --symlink --no-interaction --env=prod ; \
    rm -rf /app/src/elasticms/var/* ;