ARG NGINX_TAG=1.23.2-alpine
FROM nginx:${NGINX_TAG} AS build
ARG NGINX_TAG
ARG NGINX_VERSION=${NGINX_TAG%"-alpine"}

WORKDIR /root/

# Add brotli support
RUN apk add --update --no-cache git pcre-dev openssl-dev zlib-dev linux-headers build-base \
    && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar zxf nginx-${NGINX_VERSION}.tar.gz \
    && git clone https://github.com/google/ngx_brotli.git \
    && cd ngx_brotli \
    && git submodule update --init --recursive \
    && cd ../nginx-${NGINX_VERSION} \
    && ./configure \
    --add-dynamic-module=../ngx_brotli \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-perl_modules_path=/usr/lib/perl5/vendor_perl \
    --user=nginx \
    --group=nginx \
    --with-compat \
    --with-file-aio \
    --with-threads \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-cc-opt='-Os -fomit-frame-pointer -g' \
    --with-ld-opt=-Wl,--as-needed,-O1,--sort-common \
    && make modules

FROM nginxinc/nginx-unprivileged:${NGINX_TAG}
ARG NGINX_VERSION

COPY --from=build /root/nginx-${NGINX_VERSION}/objs/ngx_http_brotli_filter_module.so /usr/lib/nginx/modules/
COPY --from=build /root/nginx-${NGINX_VERSION}/objs/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/

# RUN cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak; echo 'load_module /usr/lib/nginx/modules/ngx_http_brotli_filter_module.so;' > /etc/nginx/nginx.conf; echo 'load_module /usr/lib/nginx/modules/ngx_http_brotli_static_module.so;' >> /etc/nginx/nginx.conf; cat /etc/nginx/nginx.conf >> /etc/nginx/nginx.conf;
RUN cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak \
    && echo 'load_module /usr/lib/nginx/modules/ngx_http_brotli_filter_module.so;' > /etc/nginx/nginx.conf \
    && echo 'load_module /usr/lib/nginx/modules/ngx_http_brotli_static_module.so;' >> /etc/nginx/nginx.conf \
    && cat /etc/nginx/nginx.conf.bak >> /etc/nginx/nginx.conf
RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx/conf.d/rbnis.conf /etc/nginx/conf.d/rbnis.conf

# Add static web page
COPY index.html /usr/share/nginx/html/index.html
COPY index.css /usr/share/nginx/html/index.css
COPY assets/ /usr/share/nginx/html/assets/
