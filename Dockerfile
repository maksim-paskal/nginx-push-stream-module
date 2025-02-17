FROM alpine:latest

COPY . /usr/src/nginx/nginx-push-stream-module
COPY misc/nginx.conf.minimal /tmp

ENV NGINX_VERSION=1.26.3

RUN CONFIG="\
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib/nginx/modules \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/tmp/nginx.pid \
  --lock-path=/tmp/nginx.lock \
  --http-client-body-temp-path=/tmp/client_temp \
  --http-proxy-temp-path=/tmp/proxy_temp \
  --http-fastcgi-temp-path=/tmp/fastcgi_temp \
  --http-uwsgi-temp-path=/tmp/uwsgi_temp \
  --http-scgi-temp-path=/tmp/scgi_temp \
  --user=nginx \
  --group=nginx \
  --with-http_ssl_module \
  --with-http_realip_module \
  --with-http_addition_module \
  --with-http_sub_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_random_index_module \
  --with-http_secure_link_module \
  --with-http_stub_status_module \
  --with-http_auth_request_module \
  --with-http_xslt_module=dynamic \
  --with-http_image_filter_module=dynamic \
  --with-http_geoip_module=dynamic \
  --with-threads \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-stream_realip_module \
  --with-stream_geoip_module=dynamic \
  --with-http_slice_module \
  --with-mail \
  --with-mail_ssl_module \
  --with-compat \
  --with-file-aio \
  --with-http_v2_module \
  --add-module=/usr/src/nginx/nginx-push-stream-module \
  " \
&& apk upgrade \
&& addgroup -S nginx \
&& adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
&& apk add --no-cache --virtual .build-deps \
  gcc \
  libc-dev \
  make \
  openssl-dev \
  pcre-dev \
  zlib-dev \
  linux-headers \
  curl \
  gpg \
  gnupg-dirmngr \
  libxslt-dev \
  gd-dev \
  geoip-dev \
&& cd /usr/src \
&& curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o /tmp/nginx-$NGINX_VERSION.tar.gz \
&& touch /tmp/checksum.txt \
&& echo "69ee2b237744036e61d24b836668aad3040dda461fe6f570f1787eab570c75aa  /tmp/nginx-$NGINX_VERSION.tar.gz" >> /tmp/checksum.txt \
&& sha256sum -c /tmp/checksum.txt \
&& tar -xzf /tmp/nginx-$NGINX_VERSION.tar.gz -C /usr/src \
&& cd /usr/src/nginx-$NGINX_VERSION \
&& ./configure $CONFIG --with-debug \
&& make -j$(getconf _NPROCESSORS_ONLN) \
&& mv objs/nginx objs/nginx-debug \
&& mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
&& mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
&& mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
&& mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so \
&& ./configure $CONFIG \
&& make -j$(getconf _NPROCESSORS_ONLN) \
&& make install \
&& strip /usr/sbin/nginx* \
&& strip /usr/lib/nginx/modules/*.so \
&& rm -rf /usr/src/nginx-$NGINX_VERSION \
&& rm -rf /tmp/nginx-$NGINX_VERSION.tar.gz \
&& rm -rf /usr/src/nginx/nginx-push-stream-module/misc \
&& rm -rf /tmp/checksum.txt \
&& apk del .build-deps \
# install nginx dependencies
&& apk add --no-cache pcre \
# forward request and error logs to docker log collector
&& ln -sf /dev/stdout /var/log/nginx/access.log \
&& ln -sf /dev/stderr /var/log/nginx/error.log \
# copy minimal nginx config and test
&& mv /tmp/nginx.conf.minimal /etc/nginx/nginx.conf \
&& nginx -t \
&& rm /tmp/nginx.pid \
&& chmod 777 -R /var/cache/nginx /var/log/nginx

USER nginx

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]