#!/bin/bash

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Available services
SERVICES=("n8n" "ollama" "caddy" "watchtower" "firefly_iii" "openwebui" "litellm")

show_usage() {
    echo -e "${BLUE}🐳 AI Server Management Script${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "${YELLOW}Usage: $0 {start|stop|restart|status|logs|backup} [service_name|all]${NC}"
    echo ""
    echo -e "${BLUE}Available services:${NC} ${SERVICES[*]}"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo "  $0 start all       # Start all services"
    echo "  $0 start           # Start all services (default)"
    echo "  $0 stop ollama     # Stop only ollama"
    echo "  $0 restart caddy   # Restart only caddy"
    echo "  $0 status n8n      # Status of n8n only"
    echo "  $0 status          # Status of all services"
    echo "  $0 logs firefly_iii    # Show logs for firefly_iii"
    echo "  $0 backup firefly_iii  # Backup firefly_iii data"
    echo ""
}

create_network() {
    if ! docker network ls | grep -q "ai_server_net"; then
        echo -e "${BLUE}📡 Creating shared network: ai_server_net${NC}"
        docker network create ai_server_net
    fi
}

start_all() {
    echo -e "${BLUE}🚀 Starting AI Server containers...${NC}"
    
    create_network
    
    # Start containers in logical order
    echo -e "${GREEN}🔧 Starting n8n...${NC}"
    docker compose -f n8n/docker-compose.yaml up -d

    echo -e "${GREEN}🤖 Starting ollama...${NC}"
    docker compose -f ollama/docker-compose.yaml up -d

    echo -e "${GREEN}💰 Starting firefly_iii...${NC}"
    docker compose -f firefly_iii/docker-compose.yml up -d

    echo -e "${GREEN}🖥️ Starting openwebui...${NC}"
    docker compose -f openwebui/docker-compose.yaml up -d

    echo -e "${GREEN}🧠 Starting litellm...${NC}"
    docker compose -f litellm/docker-compose.yaml up -d

    echo -e "${GREEN}🌐 Starting caddy...${NC}"
    docker compose -f caddy/docker-compose.yaml up -d

    echo -e "${GREEN}👁️ Starting watchtower...${NC}"
    docker compose -f watchtower/docker-compose.yaml up -d
    
    echo -e "${GREEN}✅ All containers started!${NC}"
    echo -e "${BLUE}📊 Container status:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

stop_all() {
    echo -e "${YELLOW}🛑 Stopping AI Server containers...${NC}"

    # Stop watchtower first (monitoring service)
    echo -e "${RED}👁️ Stopping watchtower...${NC}"
    docker compose -f watchtower/docker-compose.yaml down

    # Stop caddy (reverse proxy)
    echo -e "${RED}🌐 Stopping caddy...${NC}"
    docker compose -f caddy/docker-compose.yaml down

    # Stop firefly_iii
    echo -e "${RED}💰 Stopping firefly_iii...${NC}"
    docker compose -f firefly_iii/docker-compose.yml down

    # Stop openwebui
    echo -e "${RED}🖥️ Stopping openwebui...${NC}"
    docker compose -f openwebui/docker-compose.yaml down

    # Stop litellm
    echo -e "${RED}🧠 Stopping litellm...${NC}"
    docker compose -f litellm/docker-compose.yaml down

    # Stop ollama
    echo -e "${RED}🤖 Stopping ollama...${NC}"
    docker compose -f ollama/docker-compose.yaml down

    # Stop n8n
    echo -e "${RED}🔧 Stopping n8n...${NC}"
    docker compose -f n8n/docker-compose.yaml down
    
    echo -e "${YELLOW}✅ All containers stopped!${NC}"
    echo -e "${BLUE}📊 Remaining containers:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

restart_all() {
    echo -e "${YELLOW}🔄 Restarting AI Server containers...${NC}"
    stop_all
    sleep 3
    start_all
}

status_all() {
    echo -e "${BLUE}📊 AI Server Status${NC}"
    echo -e "${GREEN}==================${NC}"
    
    echo -e "\n${BLUE}🐳 Running containers:${NC}"
    docker ps --filter "name=n8n" --filter "name=caddy" --filter "name=ollama" --filter "name=watchtower" --filter "name=firefly_iii" --filter "name=openwebui" --filter "name=litellm" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo -e "\n${BLUE}📡 Networks:${NC}"
    docker network ls | grep -E "(ai_server_net|caddy_default|n8n_default|ollama_default|watchtower_default|firefly_iii|litellm_default)"
    
    echo -e "\n${BLUE}🔗 Service URLs:${NC}"
    echo "• n8n: https://n8n.aiserver.onmobilespace.com"
    echo "• Firefly III: https://firefly.aiserver.onmobilespace.com"
    echo "• OpenWebUI: https://openwebui.aiserver.onmobilespace.com"
    echo "• LiteLLM: https://litellm.aiserver.onmobilespace.com"
    echo "• Ollama API: http://localhost:11434 (if exposed)"
    echo "• Caddy Admin: http://localhost:2019"
    
    echo -e "\n${YELLOW}⏰ Watchtower Schedule:${NC}"
    echo "• Updates check: 11th of each month at 04:00 (Europe/Madrid)"
    
    echo -e "\n${BLUE}💾 Disk usage:${NC}"
    if [ -d "firefly_iii/data" ]; then
        echo "• Firefly data: $(du -sh firefly_iii/data 2>/dev/null | cut -f1)"
    fi
    if [ -d "n8n/n8n_storage" ]; then
        echo "• n8n data: $(du -sh n8n/n8n_storage 2>/dev/null | cut -f1)"
    fi
}

backup_service() {
    local service=$1
    
    case $service in
        firefly_iii)
            echo -e "${BLUE}💾 Backing up Firefly III...${NC}"
            if [ -f "firefly_iii/backup.sh" ]; then
                cd firefly_iii && ./backup.sh
                cd ..
                echo -e "${GREEN}✅ Firefly backup completed!${NC}"
            else
                echo -e "${RED}❌ Backup script not found: firefly_iii/backup.sh${NC}"
                exit 1
            fi
            ;;
        n8n)
            echo -e "${BLUE}💾 Backing up n8n...${NC}"
            BACKUP_DIR="n8n/backups"
            DATE=$(date +%Y%m%d_%H%M%S)
            mkdir -p "$BACKUP_DIR"
            
            if [ -d "n8n/n8n_storage" ]; then
                tar -czf "$BACKUP_DIR/n8n-backup-$DATE.tar.gz" -C n8n n8n_storage
                echo -e "${GREEN}✅ n8n backup completed: $BACKUP_DIR/n8n-backup-$DATE.tar.gz${NC}"
            else
                echo -e "${RED}❌ n8n data directory not found${NC}"
                exit 1
            fi
            ;;
        all)
            echo -e "${BLUE}💾 Backing up all services...${NC}"
            backup_service firefly
            backup_service n8n
            echo -e "${GREEN}✅ All backups completed!${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️  No backup script available for $service${NC}"
            ;;
    esac
}

manage_service() {
    local action=$1
    local service=$2
    
    # Check if service exists
    if [[ ! " ${SERVICES[*]} " =~ " $service " ]]; then
        echo -e "${RED}❌ Unknown service: $service${NC}"
        echo -e "${YELLOW}Available services: ${SERVICES[*]}${NC}"
        exit 1
    fi
    
    # Determine compose file name (firefly_iii uses .yml, others use .yaml)
    local compose_file="$service/docker-compose.yaml"
    if [[ $service == "firefly_iii" ]]; then
        compose_file="$service/docker-compose.yml"
    fi
    
    # Check if docker-compose file exists
    if [[ ! -f "$compose_file" ]]; then
        echo -e "${RED}❌ Docker compose file not found: $compose_file${NC}"
        exit 1
    fi
    
    case $action in
        start)
            echo -e "${GREEN}🚀 Starting $service...${NC}"
            create_network
            docker compose -f $compose_file up -d
            echo -e "${GREEN}✅ $service started!${NC}"
            docker ps --filter "name=$service" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
            ;;
        stop)
            echo -e "${RED}🛑 Stopping $service...${NC}"
            docker compose -f $compose_file down
            echo -e "${YELLOW}✅ $service stopped!${NC}"
            ;;
        restart)
            echo -e "${YELLOW}🔄 Restarting $service...${NC}"
            docker compose -f $compose_file down
            sleep 2
            create_network
            docker compose -f $compose_file up -d
            echo -e "${GREEN}✅ $service restarted!${NC}"
            docker ps --filter "name=$service" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
            ;;
        status)
            echo -e "${BLUE}📊 Status of $service:${NC}"
            docker ps --filter "name=$service" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
            
            # Show logs tail if container is running
            if docker ps --filter "name=$service" --format "{{.Names}}" | grep -q "$service"; then
                echo -e "\n${PURPLE}📝 Recent logs (last 10 lines):${NC}"
                docker compose -f $compose_file logs --tail=10
            fi
            
            # Show disk usage for firefly_iii
            if [[ $service == "firefly_iii" ]] && [ -d "firefly_iii/data" ]; then
                echo -e "\n${BLUE}💾 Disk usage:${NC}"
                du -sh firefly_iii/data/* 2>/dev/null
            fi
            ;;
        logs)
            echo -e "${PURPLE}📝 Logs for $service:${NC}"
            docker compose -f $compose_file logs -f
            ;;
        backup)
            backup_service $service
            ;;
    esac
}

# Main logic
ACTION=$1
TARGET=${2:-"all"}  # Default to "all" if no target specified

# Show usage if no action provided
if [[ -z $ACTION ]]; then
    show_usage
    exit 1
fi

# Validate action
case $ACTION in
    start|stop|restart|status|logs|backup)
        ;;
    *)
        echo -e "${RED}❌ Invalid action: $ACTION${NC}"
        show_usage
        exit 1
        ;;
esac

# Execute based on target
if [[ $TARGET == "all" ]]; then
    # All services management
    case $ACTION in
        start)
            start_all
            ;;
        stop)
            stop_all
            ;;
        restart)
            restart_all
            ;;
        status)
            status_all
            ;;
        logs)
            echo -e "${YELLOW}⚠️  Please specify a service for logs${NC}"
            echo -e "${BLUE}Example: $0 logs firefly${NC}"
            exit 1
            ;;
        backup)
            backup_service all
            ;;
    esac
else
    # Single service management
    manage_service $ACTION $TARGET
fi
