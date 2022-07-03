FROM nginxinc/nginx-unprivileged:1.23.0-alpine

# Add static web page
COPY index.html /usr/share/nginx/html/index.html
COPY index.css /usr/share/nginx/html/index.css
COPY assets/ /usr/share/nginx/html/assets/
