# Установка Apache Superset 3.1.0

```
# Клонируем проект из github
git clone https://github.com/apache/superset.git
 
# Переходим в директорию
cd superset
 
# Переключаемся на ветку релиза 3.1.0
git checkout 3.1.0
 
# Проверяем статус (что переключились на правильный тег)
git status

# Обязательно меняем версию образа, который нужно использовать при развертывании
# Делается это в файле docker-compose-non-dev.yml
# nano docker-compose-non-dev.yml

# Меняем пароль в docker-init.sh
# Отключаем загрузку примеров .env-non-dev
# SUPERSET_LOAD_EXAMPLES=no
# ---
# openssl rand -base64 42
# Выставляем SECRET_KEY = 'сюда вставляем сгенерированный хеш' в superset_config.py
# ---
# Для локального развертывания TALISMAN_ENABLED = False

# Набор фич FEATURE_FLAGS
FEATURE_FLAGS = {
    "ALERT_REPORTS": True,
    "DRILL_BY": True,
    "DRILL_TO_DETAIL": True,
    "HORIZONTAL_FILTER_BAR": True,
    "DASHBOARD_CROSS_FILTERS": True,
    "ENABLE_TEMPLATE_PROCESSING": True,
    "TAGGING_SYSTEM": True,
    "HORIZONTAL_FILTER_BAR": True,
    "ENABLE_EXPLORE_DRAG_AND_DROP": True,
    "DASHBOARD_RBAC": True,
    "LISTVIEWS_DEFAULT_CARD_VIEW": True,
}

# Запускаем установку (запустится скачивание образов с hub.docker.com)
sudo docker-compose -f docker-compose-non-dev.yml up
```