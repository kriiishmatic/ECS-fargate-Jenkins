
FROM nginx:1.29.4-alpine

# Install curl because ECS container health checks use curl
RUN apk add --no-cache curl

# Remove default configuration
RUN rm -f /etc/nginx/conf.d/default.conf

# Prepare directories for non-root Nginx
RUN mkdir -p \
    /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp && \
    chown -R nginx:nginx /var/cache/nginx /var/log/nginx

COPY nginx.conf /etc/nginx/nginx.conf
COPY static/ /usr/share/nginx/html/

USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
