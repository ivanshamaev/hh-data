# Краткая инструкция по установке Docker and Docker-Compose на Ubuntu 22.04

## Установка Docker и Docker-Compose
```
# Обновляем существующий список пакето
sudo apt update

# Далее устанавливаем пакеты, которые позволят apt использовать пакеты через HTTPS:
sudo apt install apt-transport-https ca-certificates curl software-properties-common

# Далее добавим ключ GPG для официального репозитория Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Добавляем ремозиторий докер в источники apt
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

# Обновляем базу данных пакетов и добавим в нее пакеты Docker из недавно добавленного репозитория
sudo apt update

# Далее проверим, что установка будет выполняться из репозитория Docker, а не из репозитория Ubuntu по умолчанию
apt-cache policy docker-ce

# Мы должны получить следующий ответ (номер версии Docker может отличаться):
# root@apache1superset:~# apt-cache policy docker-ce
# docker-ce:
#   Installed: (none)
#   Candidate: 5:20.10.6~3-0~ubuntu-focal
#   Version table:
#      5:20.10.6~3-0~ubuntu-focal 500
#         500 https://download.docker.com/linux/ubuntu focal/stable amd64 Packages
#      5:20.10.5~3-0~ubuntu-focal 500
#         500 https://download.docker.com/linux/ubuntu focal/stable amd64 Packages
#      5:20.10.4~3-0~ubuntu-focal 500
#         500 https://download.docker.com/linux/ubuntu focal/stable amd64 Packages
#      5:20.10.3~3-0~ubuntu-focal 500
# ...

# Далее устанавливаем докер командой (на доп.вопрос отвечаем "yes")
sudo apt install docker-ce

# Docker будет автоматически установлен, также запустится демон-процесс и будет активирован запуск при загрузке.
# Проверить статус докера можно командой (что он running/active):
sudo systemctl status docker

# Загружаем текущую стабильную версию Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Применяем разрешения для исполняемого файла к двоичному файлу
sudo chmod +x /usr/local/bin/docker-compose

# Чтобы протестировать docker-compose (установилась версия или нет), запустим команду
docker-compose --version
```

## Установка Portainer

```
sudo docker volume create portainer_data

docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
```