NAME    = inception
COMPOSE = docker compose -f srcs/docker-compose.yml -p $(NAME)
DATA_DIR = /home/$(USER)/data

all: up

up:
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean: down

fclean:
	$(COMPOSE) down -v --rmi all --remove-orphans
	sudo rm -rf $(DATA_DIR)

re: fclean up

.PHONY: all up down logs ps clean fclean re