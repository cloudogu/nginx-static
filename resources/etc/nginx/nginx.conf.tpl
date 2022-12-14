user  nginx;
worker_processes  2;

error_log  /var/log/nginx/error.log {{ .Env.Get "LOG_LEVEL" }};
pid        /var/run/nginx.pid;

events {
    worker_connections  4096;  ## Default: 1024
}

http {
    include    /etc/nginx/include.d/mime.types;

    default_type application/octet-stream;

    # logging
    {{ if not (.Config.Exists "disable_access_log") }}
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    {{end}}

    sendfile     on;
    tcp_nopush   on;
    server_names_hash_bucket_size 128; # this seems to be required for some vhosts

    include /etc/nginx/conf.d/*.conf;
}