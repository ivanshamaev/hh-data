# Installation of Nginx

```
# install
sudo apt install nginx
# check version
nginx -v

# Создаем файл конфигурации для Nginx superset
sudo nano /etc/nginx/sites-available/superset.conf

# ~~~~~~ Варик 1 ~~~~~~
server {
    listen 80;
    # Измените значение 64.159.179.83 на ваш внешний IP-адрес сервера
    server_name 64.159.179.83;
    root /var/www/superset;
    location / {
        proxy_buffers 16 4k;
        proxy_buffer_size 2k;
        proxy_pass http://127.0.0.1:8088;
        proxy_set_header Host $http_host;
    }
}

# ~~~~~~ Варик 2 ~~~~~~
server {
    listen 80;
    server_name mydomain.com;
    large_client_header_buffers 4 16k;

    location / {
        proxy_buffers 16 4k;
        proxy_buffer_size 2k;
        proxy_set_header HTTP_PROXY_REMOTE_USER $1;
        proxy_set_header Host $host:8088;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://127.0.0.1:8088;
    }
}

# Далее копируем файл
sudo ln -s /etc/nginx/sites-available/superset.conf /etc/nginx/sites-enabled

# Затем запускаем проверку синтаксиса на корректность файла и отсутствия ошибки:
sudo nginx -t

# После этого рестартуем сервис Nginx, чтобы прочитались изменения:
sudo systemctl restart nginx

```