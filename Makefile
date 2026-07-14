PROJECT_NAME := infra

# Global Targets
.PHONY: setup status clean network setup-scripts setup-registry setup-observability

setup: setup-scripts setup-registry setup-observability network databases messaging registry observability
	@echo "--- Infrastructure setup complete ---"

setup-scripts:
	@chmod +x scripts/*.sh

setup-registry:
	@./scripts/setup-registry.sh

setup-observability:
	@./scripts/setup-observability.sh



# Service Targets
.PHONY: databases messaging observability registry

databases:
	docker compose -p $(PROJECT_NAME)-db -f databases/docker-compose.yml --env-file .env up -d

messaging:
	docker compose -p $(PROJECT_NAME)-mq -f messaging/docker-compose.yml --env-file .env up -d

observability:
	docker compose -p $(PROJECT_NAME)-obs -f observability/docker-compose.yml --env-file .env up -d

registry:
	docker compose -p $(PROJECT_NAME)-reg -f registry/docker-compose.yml --env-file .env up -d

status:
	@echo "--- Infrastructure Status ---"
	@docker compose -p $(PROJECT_NAME)-db -f databases/docker-compose.yml ps
	@docker compose -p $(PROJECT_NAME)-mq -f messaging/docker-compose.yml ps
	@docker compose -p $(PROJECT_NAME)-obs -f observability/docker-compose.yml ps
	@docker compose -p $(PROJECT_NAME)-reg -f registry/docker-compose.yml ps

network:
	@docker network inspect infra-networks >/dev/null 2>&1 || docker network create infra-networks

clean:
	docker compose -p $(PROJECT_NAME)-db -f databases/docker-compose.yml down -v
	docker compose -p $(PROJECT_NAME)-mq -f messaging/docker-compose.yml down -v
	docker compose -p $(PROJECT_NAME)-obs -f observability/docker-compose.yml down -v
	docker compose -p $(PROJECT_NAME)-reg -f registry/docker-compose.yml down -v
