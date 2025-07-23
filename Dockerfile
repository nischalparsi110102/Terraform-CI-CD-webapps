# Start from official NGINX small image
FROM nginx:1.25-alpine

# Remove default site configuration (optional, but recommended)
RUN rm /etc/nginx/conf.d/default.conf

# Copy your complete nginx.conf directly into the container
COPY nginx.conf /etc/nginx/nginx.conf

# Optionally, copy your static assets into the image
COPY public/ /var/www/public/www/

# Set permissions on your static files (optional; nginx runs as root in Alpine by default)
RUN chmod -R 755 /var/www/public/www

# Expose your target port
EXPOSE 8080

# Optionally: Add a healthcheck hitting your health endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget --spider --quiet http://localhost:8080/health || exit 1

# nginx-alpine's entrypoint already launches nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
