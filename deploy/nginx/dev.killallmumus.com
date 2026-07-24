# Nginx reverse proxy for dev.killallmumus.com → Express on 127.0.0.1:3001
# Serves /var/www/dev (git branch `dev`).
#
# Install (requires sudo + DNS A record → this host):
#   sudo cp deploy/nginx/dev.killallmumus.com /etc/nginx/sites-available/dev.killallmumus.com
#   sudo ln -sfn /etc/nginx/sites-available/dev.killallmumus.com /etc/nginx/sites-enabled/
#   sudo nginx -t && sudo systemctl reload nginx
# HTTPS after DNS propagates:
#   sudo certbot --nginx -d dev.killallmumus.com

upstream killallmumus_dev_app {
    server 127.0.0.1:3001;
    keepalive 16;
}

server {
    listen 80;
    listen [::]:80;
    server_name dev.killallmumus.com;

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
        proxy_pass http://killallmumus_dev_app;
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
        # Help distinguish env in browser network tab
        add_header X-KAM-Env "dev" always;
    }
}
