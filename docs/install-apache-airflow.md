# Установка Apache Airflow 2.7.1

```
# Создаем директорию проекта airflow и переходим в нее
mkdir airflow
cd airflow

# Проверка памяти, должно быть минимум 8Гб
docker run --rm "debian:bullseye-slim" bash -c 'numfmt --to iec $(echo $(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE))))'

# Скачиваем последний docker-compose.yaml файл
# Актуальную версию файла можно найти на странице https://airflow.apache.org/docs/apache-airflow/stable/start/docker.html
curl -LfO 'https://airflow.apache.org/docs/apache-airflow/2.7.1/docker-compose.yaml'

# Далее необходимо создать директории:
# ./dags- вы можете разместить свои файлы DAG здесь.
# ./logs- содержит журналы выполнения задач и планировщика.
# ./plugins- здесь вы можете разместить свои собственные плагины.

mkdir -p ./dags ./logs ./plugins

# Создаем файл .env с параметром AIRFLOW_UUID
echo -e "AIRFLOW_UID=$(id -u)" > .env

# Инициализируем базу данных
sudo docker-compose up airflow-init

# Запуск Apache Airflow с помощью docker-compose
sudo docker-compose up
```

Далее нужно зайти в профиль юзера и поменять пароль (http://serverip:8080/).