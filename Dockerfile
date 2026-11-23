FROM nginx:stable-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html book.html lesson.html favicon.ico robots.txt /usr/share/nginx/html/
COPY static /usr/share/nginx/html/static
COPY images /usr/share/nginx/html/images
COPY LICENSE /usr/share/doc/nce/LICENSE
