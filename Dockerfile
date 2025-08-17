ARG NGINX_VERSION=1.29.0-alpine
ARG TARGETARCH

FROM nginx:${NGINX_VERSION} AS build

WORKDIR /root/

# Add build dependencies
RUN apk add --update --no-cache git pcre2-dev openssl-dev zlib-dev linux-headers build-base cmake

# Download sources
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION%"-alpine"}.tar.gz \
    && tar zxf nginx-${NGINX_VERSION%"-alpine"}.tar.gz \
    && git clone https://github.com/google/ngx_brotli.git \
    && git -C ./ngx_brotli submodule update --init --recursive --depth 1 \
    && git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git

# Build brotli
RUN cd /root/ngx_brotli/deps/brotli \
    && mkdir out && cd out \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_C_FLAGS="-Ofast -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" \
      -DCMAKE_CXX_FLAGS="-Ofast -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" \
      -DCMAKE_INSTALL_PREFIX=./installed .. \
    && cmake --build . --config Release --target brotlienc

# Build nginx modules
RUN cd /root/nginx-${NGINX_VERSION%"-alpine"} \
    && sh -c 'set -eux && eval ./configure \
      $(nginx -V 2>&1 | sed -n -e "s/^.*configure arguments: //p") \
      --add-dynamic-module=/root/ngx_brotli \
      --add-dynamic-module=/root/ngx_http_substitutions_filter_module' \
    && make modules

FROM nginxinc/nginx-unprivileged:${NGINX_VERSION}

ENV NGINX_ENTRYPOINT_QUIET_LOGS=true

COPY --from=build /root/nginx-${NGINX_VERSION%"-alpine"}/objs/ngx_http_brotli_filter_module.so /usr/lib/nginx/modules/
COPY --from=build /root/nginx-${NGINX_VERSION%"-alpine"}/objs/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/
COPY --from=build /root/nginx-${NGINX_VERSION%"-alpine"}/objs/ngx_http_subs_filter_module.so /usr/lib/nginx/modules/
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Add static web page
COPY index.html /usr/share/nginx/html/index.html
COPY *.css /usr/share/nginx/html/
COPY assets/ /usr/share/nginx/html/assets/
COPY well-known/ /usr/share/nginx/html/well-known/
