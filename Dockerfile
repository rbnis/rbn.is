FROM rbnis/static-web:latest

# Add static web page
COPY index.html /var/www/index.html
COPY index.css /var/www/index.css
COPY assets/ /var/www/assets/
