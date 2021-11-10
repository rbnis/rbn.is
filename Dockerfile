FROM nginx:1.21.4-alpine

# Add static web page
COPY index.html /usr/share/nginx/html/index.html
COPY index.css /usr/share/nginx/html/index.css
COPY assets/ /usr/share/nginx/html/assets/
