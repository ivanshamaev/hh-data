# Installation of Nginx

```
# update
sudo apt update

# install
sudo apt install nginx

# check version
nginx -v
```

## Настройка Apache Superset для адреса hh-data.ru/superset

! ПОКА НЕРАБОЧАЯ НАСТРОЙКА

```
# Создаем файл конфигурации для Nginx superset
sudo nano /etc/nginx/sites-available/superset.conf


server {
    listen 80;
    server_name hh-data.ru;
    large_client_header_buffers 4 16k;

    location /superset/ {
        proxy_pass http://127.0.0.1:8088/;
        proxy_set_header Host $host:8088;
        proxy_set_header X-Real-IP $remote_addr;
        
        proxy_buffers 16 4k;
        proxy_buffer_size 2k;
        proxy_set_header Host $http_host;
    }
}


# Далее копируем файл
sudo ln -s /etc/nginx/sites-available/superset.conf /etc/nginx/sites-enabled

# Для обновления уже существующего файла можно использовать команду
sudo ln -sf /etc/nginx/sites-available/superset.conf /etc/nginx/sites-enabled

# Затем запускаем проверку синтаксиса на корректность файла и отсутствия ошибки:
sudo nginx -t

# После этого рестартуем сервис Nginx, чтобы прочитались изменения:
sudo systemctl restart nginx

```

## Настройка Apache Airflow для адреса hh-data.ru/airflow

```
todo
```