ARG NGINX_VERSION=1.27.0-alpine
FROM nginx:${NGINX_VERSION} AS build
ARG NGINX_VERSION

WORKDIR /root/

# Add brotli support
# Add build dependencies
RUN apk add --update --no-cache git pcre-dev openssl-dev zlib-dev linux-headers build-base cmake
# Download sources
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION%"-alpine"}.tar.gz \
    && tar zxf nginx-${NGINX_VERSION%"-alpine"}.tar.gz \
    && git clone https://github.com/google/ngx_brotli.git && cd ngx_brotli \
    && git submodule update --init --recursive --depth 1
# Build brotli
RUN cd /root/ngx_brotli/deps/brotli \
    && mkdir out && cd out \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed .. \
    && cmake --build . --config Release --target brotlienc
# Build nginx
RUN cd /root/nginx-${NGINX_VERSION%"-alpine"} \
    && ./configure \
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
      --with-http_v3_module \
      --with-mail \
      --with-mail_ssl_module \
      --with-stream \
      --with-stream_realip_module \
      --with-stream_ssl_module \
      --with-stream_ssl_preread_module \
      --with-cc-opt='-Os -Wformat -Werror=format-security -g' \
      --with-ld-opt='-Wl,--as-needed,-O1,--sort-common -Wl,-z,pack-relative-relocs' \
      --add-dynamic-module=/root/ngx_brotli \
    && make modules \
    && cp /root/nginx-${NGINX_VERSION%"-alpine"}/objs/ngx_http_brotli_filter_module.so /root/ \
    && cp /root/nginx-${NGINX_VERSION%"-alpine"}/objs/ngx_http_brotli_static_module.so /root/


FROM nginxinc/nginx-unprivileged:${NGINX_VERSION}

ENV NGINX_ENTRYPOINT_QUIET_LOGS true

COPY --from=build /root/ngx_http_brotli_filter_module.so /usr/lib/nginx/modules/
COPY --from=build /root/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Add static web page
COPY index.html /usr/share/nginx/html/index.html
COPY index.css /usr/share/nginx/html/index.css
COPY assets/ /usr/share/nginx/html/assets/
