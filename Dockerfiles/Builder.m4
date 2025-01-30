ENV ELASTICMS_VERSION=${VERSION_ARG:-6.0.0} \
    ELASTICMS_DOWNLOAD_URL="https://github.com/ems-project/elasticms-admin/archive"

RUN echo "Download and install ElastiCMS ..." \
    && mkdir -p /app/src/elasticms \
    && curl -sSfLk ${ELASTICMS_DOWNLOAD_URL}/${ELASTICMS_VERSION}.tar.gz \
       | tar -xzC /app/src/elasticms --strip-components=1 \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv install --no-interaction --no-suggest --no-scripts --working-dir /app/src/elasticms -o  \
    && rm -rf /app/src/elasticms/bootstrap/cache/* /app/src/elasticms/.env /app/src/elasticms/.env.dist