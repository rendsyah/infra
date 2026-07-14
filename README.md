# Infrastructure Management Stack

A modular Docker-based infrastructure management system encompassing Databases, Messaging, Private Registry, and Observability.

## 🏗️ Project Structure

The project is organized into independent modules:

*   **`databases/`**: MariaDB (10.11 LTS), PostgreSQL (16), MongoDB (8.0), and Redis (7.2).
*   **`messaging/`**: RabbitMQ (4.2-management).
*   **`registry/`**: Private Docker Registry (v2).
*   **`proxy/`**: Nginx Reverse Proxy configuration.
*   **`observability/`**: Monitoring stack using Loki (Logs), Grafana (Dashboards), and Fluent-bit (Log Collector).
*   **`scripts/`**: Utility scripts for backups and maintenance.

## 🚀 Prerequisites

1.  **Docker & Docker Compose** installed on your system.
2.  **Make** utility installed (highly recommended for ease of use).
3.  Copy `.env.example` to `.env` and configure your passwords:
    ```bash
    cp .env.example .env
    ```

## 🛠️ Usage (Makefile)

Use the `Makefile` commands from the root directory to manage the stack:

| Command | Description |
| :--- | :--- |
| `make setup` | Start **all** services and prepare scripts. |
| `make status` | Check the health status of all containers. |
| `make clean` | Remove all containers and their volumes. |
| `make network` | Ensure the shared network exists. |
| `make init-scripts` | Ensure all maintenance scripts are executable. |

### Module-Specific Management
You can also manage each module independently using the following commands:
*   **Databases**: `make databases`
*   **Messaging**: `make messaging`
*   **Registry**: `make registry`
*   **Observability**: `make observability`

## 📊 Observability (Monitoring)

The monitoring stack is accessible via:
*   **Grafana**: `http://localhost:3000` (Default login: `admin/admin`)
*   **Loki**: Automatically integrated as a datasource in Grafana.
*   **Fluent-bit**: Automatically collects logs from all running Docker containers.

## 🔒 Security & Ports

By default, all database ports are bound to `127.0.0.1` to ensure they are only accessible locally from the host machine. To expose them to the network, modify the ports configuration in the respective `docker-compose.yml` files.

| Service | Internal Port | External Port (Local Only) |
| :--- | :--- | :--- |
| MariaDB | 3306 | 3306 |
| PostgreSQL | 5432 | 5432 |
| MongoDB | 27017 | 27017 |
| Redis | 6379 | 6379 |
| RabbitMQ | 5672, 15672 | 5672, 15672 |
| Registry | 5000 | 5000 |
| Grafana | 3000 | 3000 |
| Loki | 3100 | 3100 |

## 📝 Maintenance Notes

*   **Persistence**: All persistent data is stored in local directories within each module (e.g., `databases/mariadb/data`).
*   **Version Control**: Data directories are ignored by `.gitignore` to keep the repository clean.
*   **Backups**: Use the `scripts/` directory for regular database backups.
*   **Logs**: All script logs (backup, restore, cleanup) are stored in `/var/log/infra/`.
