FROM rbnis/static-web:latest

# Add static web page
COPY index.min.html /var/www/index.html
COPY index.min.css /var/www/index.css
COPY assets/ /var/www/assets/
