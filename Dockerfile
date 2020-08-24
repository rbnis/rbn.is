FROM rbnis/static-web:latest

# Add static web page
COPY index* /var/www/
COPY assets/ /var/www/assets/
