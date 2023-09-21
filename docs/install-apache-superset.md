# Установка Apache Superset 2.1.1

```
# Клонируем проект из github
git clone https://github.com/apache/superset.git
 
# Переходим в директорию
cd superset
 
# Переключаемся на ветку релиза 2.1.1
git checkout 2.1.1
 
# Проверяем статус (что переключились на правильный тег)
git status

# Обязательно меняем версию образа, который нужно использовать при развертывании
# Делается это в файле docker-compose-non-dev.yml

# Меняем пароль в docker-init.sh
# Отключаем загрузку примеров .env-non-dev
# Выставляем SECRET_KEY = в superset_config.py

# Запускаем установку (запустится скачивание образов с hub.docker.com)
sudo docker-compose -f docker-compose-non-dev.yml up
```