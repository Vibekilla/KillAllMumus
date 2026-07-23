# Nginx reverse proxy for killallmumus.com → Express game (127.0.0.1:3000)
# Install (requires sudo):
#   sudo cp deploy/nginx/killallmumus.com /etc/nginx/sites-available/killallmumus.com
#   sudo ln -sfn /etc/nginx/sites-available/killallmumus.com /etc/nginx/sites-enabled/
#   sudo rm -f /etc/nginx/sites-enabled/default
#   sudo nginx -t && sudo systemctl reload nginx
# HTTPS after DNS:
#   sudo apt install -y certbot python3-certbot-nginx
#   sudo certbot --nginx -d killallmumus.com -d www.killallmumus.com

upstream killallmumus_app {
    server 127.0.0.1:3000;
    keepalive 32;
}

server {
    listen 80;
    listen [::]:80;
    server_name www.killallmumus.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 http://killallmumus.com$request_uri;
    }
}

server {
    listen 80;
    listen [::]:80;
    server_name killallmumus.com;

    server_tokens off;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 5;
    gzip_types text/plain text/css text/xml application/json application/javascript
               application/xml image/svg+xml font/woff2;

    location / {
        proxy_pass http://killallmumus_app;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    }
}
