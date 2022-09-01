#!/bin/bash

function create-ems-folders {

  if [ ! -z "$STORAGE_FOLDER" ]; then
    if [ ! -d "$STORAGE_FOLDER" ]; then
      echo "Try to create $STORAGE_FOLDER missing folder."
      mkdir -p $STORAGE_FOLDER
    fi
  else
    if [ ! -d /var/lib/ems/assets ]; then
      echo "Try to create (default) /var/lib/ems/assets missing folder."
      mkdir -p /var/lib/ems/assets
    fi
  fi

  if [ ! -z "$EMS_UPLOAD_FOLDER" ]; then
    if [ ! -d "$EMS_UPLOAD_FOLDER" ]; then
      echo "Try to create $EMS_UPLOAD_FOLDER missing folder."
      mkdir -p $EMS_UPLOAD_FOLDER
    fi
  else
    if [ ! -d /var/lib/ems/uploads ]; then
      echo "Try to create (default) /var/lib/ems/uploads missing folder."
      mkdir -p /var/lib/ems/uploads
    fi
  fi

  if [ ! -z "$EMS_DUMPS_FOLDER" ]; then
    if [ ! -d "$EMS_DUMPS_FOLDER" ]; then
      echo "Try to create $EMS_DUMPS_FOLDER missing folder."
      mkdir -p $EMS_DUMPS_FOLDER
    fi
  else
    if [ ! -d /var/lib/ems/dumps ]; then
      echo "Try to create (default) /var/lib/ems/dumps missing folder."
      mkdir -p /var/lib/ems/dumps
    fi
  fi

}

function configure-supervisord-eventlistener {
  local -r _instance_name=$1

  mkdir -p /etc/supervisord/supervisord.d

  cat >/etc/supervisord/supervisord.d/$_instance_name.ini <<EOL
[eventlistener:$_instance_name]
command=/opt/bin/supervisord-event-listener.py /opt/bin/ems-jobs/$_instance_name
events=TICK_60
autorestart=false
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOL

}

function create-wrapper-scripts {
  local -r _instance_name=$1

  mkdir -p /opt/bin/ems-jobs

  cat >/opt/bin/$_instance_name <<EOL
#!/bin/bash
# This script is autogenerated by the container startup script
set -o allexport
source /tmp/$_instance_name
set +o allexport

if [ \${1:-list} = sql ] || [ \${1:-list} = dump ] ; then
  if [ \${DB_DRIVER:-mysql} = mysql ] ; then
    if [ \${1:-list} = sql ] ; then
      mysql --port=\$DB_PORT --host=\$DB_HOST --user=\$DB_USER --password=\$(urlencode.py \$DB_PASSWORD) \$DB_NAME
    else
      mysqldump --port=\$DB_PORT --host=\$DB_HOST --user=\$DB_USER --password=\$(urlencode.py \$DB_PASSWORD) \$DB_NAME
    fi;
  elif [ \${DB_DRIVER:-mysql} = pgsql ] ; then
    if [ \${1:-list} = sql ] ; then
      psql postgresql://\${DB_USER}:\$(urlencode.py \$DB_PASSWORD)@\${DB_HOST//,/:\${DB_PORT},}:\${DB_PORT}/\${DB_NAME}?connect_timeout=\${DB_CONNECTION_TIMEOUT:-30} \${@:2}
    else
      pg_dump postgresql://\${DB_USER}:\$(urlencode.py \$DB_PASSWORD)@\${DB_HOST//,/:\${DB_PORT},}:\${DB_PORT}/\${DB_NAME}?connect_timeout=\${DB_CONNECTION_TIMEOUT:-30} -w --clean -Fp -O --schema=\${DB_SCHEMA:-public} | sed "/^\(DROP\|ALTER\|CREATE\) SCHEMA.*\$/d"
    fi;
  else
    echo Driver \$DB_DRIVER not supported
  fi;
else
  export EMS_PROCESS_COMMAND=$_instance_name
  php -d memory_limit=\${CLI_PHP_MEMORY_LIMIT:-512M} /opt/src/bin/console \$@
fi;
EOL

  cat >/opt/bin/ems-jobs/$_instance_name <<EOL
#!/bin/bash

echo ---
echo Running ems-jobs for [ $_instance_name ]
echo ---

/opt/bin/$_instance_name ems:job:run ${JOBS_OPTS}

EOL

  chmod a+x /opt/bin/$_instance_name
  chmod a+x /opt/bin/ems-jobs/$_instance_name

}

function create-apache-vhost {
  local -r _name=$1

  echo "Configure Apache Virtual Host for [ ${_name} ] CMS Domains [ ${SERVER_NAME} ] ..."

  if [ -f /etc/apache2/conf.d/${_name}-app.conf ] ; then
    rm /etc/apache2/conf.d/${_name}-app.conf
  fi

  cat > /etc/apache2/conf.d/${_name}-app.conf <<EOL
# This VirtualHost is autogenerated by the container startup script
<VirtualHost *:9000>
    ServerName $SERVER_NAME
EOL

  if ! [ -z ${SERVER_ALIASES+x} ]; then
    echo "Configure Apache ServerAlias [ ${SERVER_ALIASES} ] ..."
    cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
    ServerAlias $SERVER_ALIASES
EOL
  fi

  cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
    LimitRequestLine 16384

    # Uncomment the following line to force Apache to pass the Authorization
    # header to PHP: required for "basic_auth" under PHP-FPM and FastCGI
    #
    # SetEnvIfNoCase ^Authorization$ "(.+)" HTTP_AUTHORIZATION=\$1

    # For Apache 2.4.9 or higher
    # Using SetHandler avoids issues with using ProxyPassMatch in combination
    # with mod_rewrite or mod_autoindex
    <FilesMatch \.php\$>
        SetHandler "proxy:unix:/var/run/php-fpm/php-fpm.sock|fcgi://localhost/"
    </FilesMatch>

    DocumentRoot /opt/src/public
    <Directory /opt/src/public >
        AllowOverride None
        Order Allow,Deny
        Allow from All
        Require all granted
        FallbackResource /index.php
    </Directory>

    ErrorLog /dev/stderr
    CustomLog /dev/stdout common
    RewriteEngine On
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

EOL

  if ! [ -z ${ALIAS+x} ]; then
    echo "Configure Apache Alias [ ${ALIAS} ] ..."
    echo "Caution: do not add an alias that exists somewhere in a ems route (i.e. admin)"
    cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
        Alias $ALIAS /opt/src/public

        RewriteCond %{REQUEST_URI} ^$ALIAS/bundles/emsch_assets/ [OR]
        RewriteCond %{REQUEST_URI} ^$ALIAS/bundles/data/ [OR]
        RewriteCond %{REQUEST_URI} ^$ALIAS/bundles/public/ [OR]
        RewriteCond %{REQUEST_URI} ^$ALIAS/bundles/asset/
        RewriteRule "^$ALIAS" "$ALIAS/index.php\$1" [PT]

        RewriteCond %{REQUEST_URI} !^$ALIAS/index.php
        RewriteCond %{REQUEST_URI} !^$ALIAS/bundles/
        RewriteCond %{REQUEST_URI} !^$ALIAS/favicon.ico\$
        RewriteCond %{REQUEST_URI} !^$ALIAS/apple-touch-icon.png\$
        RewriteCond %{REQUEST_URI} !^$ALIAS/robots.txt\$
        RewriteRule "^$ALIAS" "$ALIAS/index.php\$1" [PT]
EOL
  fi

  echo "Configure Apache Environment Variables ..."
  cat /tmp/${_name} | sed '/^\s*$/d' | grep  -v '^#' | sed "s/\([a-zA-Z0-9_]*\)\=\(.*\)/        SetEnv \1 \2/g" >> /etc/apache2/conf.d/${_name}-app.conf

  cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL

</VirtualHost>
EOL

  echo "Apache Virtual Host for [ ${_name} ] CMS Domains [ ${SERVER_NAME} ] configured successfully ..."

}

# fork a subprocess
function configure (

  local -r _name=$1
  local -r _today=$(date +"%Y_%m_%d")

  source /tmp/${_name}

  create-apache-vhost "${_name}"
  create-wrapper-scripts "${_name}"

  if [ -z ${JOBS_ENABLED} ] || [ "${JOBS_ENABLED}" != "true" ]; then
    echo "Use PHP-FPM for running EMS Jobs ..."
  else
    echo "Use Supervisord for running EMS Jobs ..."
    configure-supervisord-eventlistener "${_name}"
  fi

  create-ems-folders

  if [[ "$DB_DRIVER" =~ ^.*pgsql$ ]]; then
    if [[ "$DB_USER" =~ ^.*_(chg)$ ]]; then
      echo "Startup DBCR() ..."
      psql postgresql://${DB_USER}:$(urlencode.py $DB_PASSWORD)@${DB_HOST//,/:${DB_PORT},}:${DB_PORT}/${DB_NAME}?connect_timeout=${DB_CONNECTION_TIMEOUT:-30} -c 'select * from start_dbcr();'
    fi
  fi

  echo "Running Doctrine database migration for [ $_name ] CMS Domain ..."
  /opt/bin/$_name doctrine:migrations:migrate --no-interaction
  if [ $? -eq 0 ]; then
    echo "Doctrine database migration for [ $_name ] CMS Domain run successfully ..."
  else
    echo "Warning: something doesn't work with Doctrine database migration !"
  fi

  if [[ "$DB_DRIVER" =~ ^.*pgsql$ ]]; then
    if [[ "$DB_USER" =~ ^.*_(chg)$ ]]; then
      echo "Stop DBCR() ..."
      psql postgresql://${DB_USER}:$(urlencode.py $DB_PASSWORD)@${DB_HOST//,/:${DB_PORT},}:${DB_PORT}/${DB_NAME}?connect_timeout=${DB_CONNECTION_TIMEOUT:-30} -c 'select * from stop_dbcr();'
    fi
  fi

  echo "Running Elasticms assets installation to /opt/src/public folder for [ $_name ] CMS Domain ..."
  /opt/bin/$_name asset:install /opt/src/public --symlink --no-interaction
  if [ $? -eq 0 ]; then
    echo "Elasticms assets installation for [ $_name ] CMS Domain run successfully ..."
  else
    echo "Warning: something doesn't work with Elasticms assets installation !"
  fi

  echo "Running Elasticms cache warming up for [ $_name ] CMS Domain ..."
  /opt/bin/$_name cache:warm --no-interaction --env=prod
  if [ $? -eq 0 ]; then
    echo "Elasticms warming up for [ $_name ] CMS Domain run successfully ..."
  else
    echo "Warning: something doesn't work with Elasticms cache warming up !"
  fi

)

function install {

  if [ ! -z "$AWS_S3_CONFIG_BUCKET_NAME" ]; then
    echo "Found AWS_S3_CONFIG_BUCKET_NAME environment variable.  Reading properties files ..."

    export AWS_S3_CONFIG_BUCKET_NAME=${AWS_S3_CONFIG_BUCKET_NAME#s3://}

    list=(`aws s3 ls ${AWS_S3_CONFIG_BUCKET_NAME%/}/ ${AWS_CLI_EXTRA_ARGS} | awk '{print $4}'`)

    for config in ${list[@]};
    do

      name=${config%.*}

      echo "Install [ $name ] CMS Domain from S3 Bucket [ $config ] file ..."

      aws s3 cp s3://${AWS_S3_CONFIG_BUCKET_NAME%/}/$config ${AWS_CLI_EXTRA_ARGS} - | envsubst > /tmp/$name

      configure "${name}"

      echo "Install [ $name ] CMS Domain from S3 Bucket [ $config ] file successfully ..."

    done

  elif [ "$(ls -A /opt/secrets)" ]; then

    echo "Found '/opt/secrets' folder with files.  Reading properties files ..."

    for file in /opt/secrets/*; do

      filename=$(basename $file)
      name=${filename%.*}

      echo "Install [ $name ] CMS Domain from FS Folder /opt/secrets/ [ $filename ] file ..."

      envsubst < $file > /tmp/$name

      configure "${name}"

      echo "Install [ $name ] CMS Domain from FS Folder /opt/secrets/ [ $filename ] file successfully ..."

    done

  elif [ "$(ls -A /opt/configs)" ]; then

    echo "Found '/opt/configs' folder with files.  Reading properties files ..."

    for file in /opt/configs/*; do

      filename=$(basename $file)
      name=${filename%.*}

      echo "Install [ $name ] CMS Domain from FS Folder /opt/configs/ [ $filename ] file ..."

      envsubst < $file > /tmp/$name

      configure "${name}"

      echo "Install [ $name ] CMS Domain from FS Folder /opt/configs/ [ $filename ] file successfully ..."

    done

  else

    echo "Install [ default ] CMS Domain from Environment variables ..."

    env | envsubst > /tmp/default

    configure "default"

    echo "Install [ default ] CMS Domain from Environment variables successfully ..."

  fi

}

if [ ! -z "$AWS_S3_ENDPOINT_URL" ]; then
  echo "Found AWS_S3_ENDPOINT_URL environment variable.  Add --endpoint-run argument to AWS CLI"
  AWS_CLI_EXTRA_ARGS="--endpoint-url ${AWS_S3_ENDPOINT_URL}"
fi

install
