#!/bin/bash
# Install dockerctl - Docker TUI by RAFAEL

echo "Installing dockerctl..."

sudo tee /usr/local/bin/dockerctl > /dev/null << 'ENDOFSCRIPT'
#!/bin/bash
# dockerctl - Docker TUI by RAFAEL
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

h() { clear; echo -e "${CYAN}============================================${NC}"; echo -e "${CYAN}        DockerCtl - Docker TUI${NC}"; echo -e "${CYAN}============================================${NC}"; echo ""; }
ok() { echo -e "${GREEN}[OK] $1${NC}"; }
err() { echo -e "${RED}[X] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }

if ! command -v docker &> /dev/null; then
    err "Docker not installed"
    exit 1
fi

select_container() {
    local containers=$(docker ps -a --format "{{.ID}}|{{.Names}}" 2>/dev/null)
    if [ -z "$containers" ]; then
        warn "No containers"
        return 1
    fi
    local names=(); local ids=()
    while IFS='|' read -r id name; do names+=("$name"); ids+=("$id"); done <<< "$containers"
    echo ""; echo "Select container:"; select name in "${names[@]}" "Back"; do
        [ "$name" = "Back" ] && return 1
        [ -n "$name" ] && { echo "${ids[$((REPLY-1))}"; return 0; }
    done
}

while true; do
    h
    echo "  [1] Containers  [2] Images  [3] Networks  [4] Volumes"
    echo "  [5] Actions  [6] Troubleshoot  [7] Quick Run  [8] Cleanup  [0] Exit"
    read -p "Select: " m
    case $m in
        1) h; docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"; read -p "Enter..."; ;;
        2) h; docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"; read -p "Enter..."; ;;
        3) h; docker network ls; read -p "Enter..."; ;;
        4) h; docker volume ls; read -p "Enter..."; ;;
        5) while true; do h; echo "  [1] Bash  [2] Logs  [3] Inspect  [4] Stats  [0] Back"; read -p "Select: " a; case $a in 
            1) d=$(select_container)||continue; docker exec -it "$d" bash 2>/dev/null||docker exec -it "$d" sh;; 
            2) d=$(select_container)||continue; docker logs -f "$d";; 
            3) d=$(select_container)||continue; docker inspect "$d"|less;; 
            4) d=$(select_container)||continue; docker stats "$d";; 
            0) break;; esac; done;;
        6) while true; do h; echo "  [1] Disk  [2] Network  [0] Back"; read -p "Select: " t; case $t in 
            1) h; docker system df -v; read -p "Prune? (y/N): " p; [[ $p == [yY] ]] && docker system prune -a -f && ok "Cleaned";; 
            0) break;; esac; done;;
        7) h; echo "1) Alpine 2) Ubuntu 3) Nginx 4) Redis"; read -p "Choice: " q; case $q in 
            1) docker run -it --rm alpine sh;; 2) docker run -it --rm ubuntu bash;; 
            3) docker run -d -p 8080:80 nginx;; 4) docker run -d -p 6379:6379 redis;; esac;;
        8) h; echo "1) Containers 2) Images 3) Volumes 4) Networks 5) All"; read -p "Choice: " u; case $u in 
            1) docker container prune -f && ok "Done";; 
            2) docker image prune -f && ok "Done";; 
            3) docker volume prune -f && ok "Done";; 
            4) docker network prune -f && ok "Done";; 
            5) docker system prune -a -f && ok "Done";; esac;;
        0) exit 0;;
    esac
done
ENDOFSCRIPT

sudo chmod +x /usr/local/bin/dockerctl
echo "dockerctl installed successfully!"
echo "Run: dockerctl"