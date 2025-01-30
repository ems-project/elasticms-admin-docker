LABEL be.fgov.elasticms.admin.build-date=$BUILD_DATE_ARG \
      be.fgov.elasticms.admin.name="elasticms-admin" \
      be.fgov.elasticms.admin.description="Admin of the ElasticMS suite." \
      be.fgov.elasticms.admin.url="https://hub.docker.com/repository/docker/elasticms/admin" \
      be.fgov.elasticms.admin.vcs-ref=$VCS_REF_ARG \
      be.fgov.elasticms.admin.vcs-url="https://github.com/ems-project/elasticms-admin-docker" \
      be.fgov.elasticms.admin.vendor="sebastian.molle@gmail.com" \
      be.fgov.elasticms.admin.version="$VERSION_ARG" \
      be.fgov.elasticms.admin.release="$RELEASE_ARG" \
      be.fgov.elasticms.admin.schema-version="1.0"

USER root

COPY --chmod=775 --chown=${PUID:-1001}:0 bin/ /app/bin/
COPY --chmod=664 --chown=${PUID:-1001}:0 config/ /app/config/

COPY --chmod=664 --chown=${PUID:-1001}:0 --from=builder /app/src/elasticms /app/src/elasticms

ENV APP_DISABLE_DOTENV=true \
    EMS_METRIC_PORT="9090" \
    PATH=/app/bin:/app/sbin:/usr/local/bin:/usr/bin:$PATH

RUN echo -e "\nListen ${EMS_METRIC_PORT}\n" >> /etc/apache2/httpd.conf \
    && find /app -type d -exec chmod ugo+x {} \;

USER ${PUID:-1001}

EXPOSE ${EMS_METRIC_PORT}/tcp

HEALTHCHECK --start-period=10s --interval=1m --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1