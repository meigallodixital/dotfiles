#!/bin/bash

# ─────────────────────────────────────────────────────────────
# dotfiles install.sh — Instalador idempotente
# ─────────────────────────────────────────────────────────────

set -o pipefail

# ── Colores ────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ── Variables globales ─────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
HOME_DIR="${HOME}"
CONFIG_DIR="${HOME_DIR}/.config"
BACKUPS_DIR="${DOTFILES_DIR}/.backups"
INSTALL_STATE="${DOTFILES_DIR}/.install-state"
INSTALL_LOG="${DOTFILES_DIR}/.install.log"

# ── Modos de operación ─────────────────────────────────────
DRY_RUN=0
FORCE=0
CHECK_ONLY=0
RESTORE_BACKUP=""

# ─────────────────────────────────────────────────────────────
# Funciones de logging
# ─────────────────────────────────────────────────────────────

log_info() {
    echo -e "${BLUE}ℹ${NC} $*" | tee -a "$INSTALL_LOG"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*" | tee -a "$INSTALL_LOG"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*" | tee -a "$INSTALL_LOG"
}

log_error() {
    echo -e "${RED}✗${NC} $*" | tee -a "$INSTALL_LOG"
}

log_section() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$INSTALL_LOG"
    echo -e "${BLUE}$*${NC}" | tee -a "$INSTALL_LOG"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$INSTALL_LOG"
}

# ─────────────────────────────────────────────────────────────
# Funciones de utilidad
# ─────────────────────────────────────────────────────────────

prompt_yes_no() {
    local prompt="$1"
    local response
    
    while true; do
        echo -ne "${YELLOW}?${NC} $prompt [y/N]: "
        read -r response
        case "$response" in
            [Yy]*) return 0 ;;
            [Nn]*|"") return 1 ;;
            *) echo "Por favor responde 'y' o 'n'" ;;
        esac
    done
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ─────────────────────────────────────────────────────────────
# Detección del sistema
# ─────────────────────────────────────────────────────────────

detect_hostname() {
    hostname
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

detect_gpu() {
    if lspci 2>/dev/null | grep -q "NVIDIA"; then
        echo "NVIDIA"
    elif lspci 2>/dev/null | grep -q "AMD"; then
        echo "AMD"
    elif lspci 2>/dev/null | grep -q "Intel"; then
        echo "Intel"
    else
        echo "unknown"
    fi
}

detect_monitors() {
    if command_exists hyprctl; then
        hyprctl monitors 2>/dev/null | grep "^Monitor" | wc -l
    else
        echo "0"
    fi
}

# ─────────────────────────────────────────────────────────────
# Validación de dependencias
# ─────────────────────────────────────────────────────────────

check_basic_deps() {
    log_info "Validando herramientas básicas..."
    
    local missing_deps=()
    
    for cmd in git ln mkdir; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Herramientas faltantes: ${missing_deps[*]}"
        return 1
    fi
    
    log_success "Herramientas básicas OK"
    return 0
}

check_hyprland_deps() {
    log_info "Validando dependencias de Hyprland..."
    
    local missing_deps=()
    local optional_deps=()
    
    for cmd in hyprland hyprctl hyprshot; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    for cmd in foot wofi; do
        if ! command_exists "$cmd"; then
            optional_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dependencias faltantes: ${missing_deps[*]}"
        return 1
    fi
    
    if [ ${#optional_deps[@]} -gt 0 ]; then
        log_warn "Dependencias opcionales faltantes: ${optional_deps[*]}"
    fi
    
    log_success "Dependencias de Hyprland OK"
    return 0
}

# ─────────────────────────────────────────────────────────────
# Sistema de backups
# ─────────────────────────────────────────────────────────────

backup_existing_config() {
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local backup_path="${BACKUPS_DIR}/${timestamp}"
    
    if [ ! -d "$CONFIG_DIR/hypr" ]; then
        log_info "No hay configuración anterior que respaldar"
        return 0
    fi
    
    log_info "Creando backup de configuración anterior..."
    mkdir -p "$backup_path"
    
    if [ -d "$CONFIG_DIR/hypr" ]; then
        cp -r "$CONFIG_DIR/hypr" "$backup_path/" 2>/dev/null || true
        log_success "Backup de hypr creado"
    fi
    
    echo "$backup_path"
}

restore_backup() {
    local backup_path="$1"
    
    if [ ! -d "$backup_path" ]; then
        log_error "Backup no encontrado: $backup_path"
        return 1
    fi
    
    log_warn "Restaurando backup desde: $backup_path"
    
    if [ -d "$backup_path/hypr" ]; then
        rm -rf "$CONFIG_DIR/hypr"
        cp -r "$backup_path/hypr" "$CONFIG_DIR/"
        log_success "Hypr restaurado"
    fi
}

# ─────────────────────────────────────────────────────────────
# Generación dinámica de host.lua
# ─────────────────────────────────────────────────────────────

generate_host_file() {
    local hostname="$1"
    local gpu_type="$2"
    local monitor_count="$3"
    local target_file="${DOTFILES_DIR}/hypr/hosts/${hostname}.lua"
    
    log_info "Generando archivo de host: $target_file"
    
    # Determinar configuración de GPU
    local gpu_config=""
    if [ "$gpu_type" = "NVIDIA" ]; then
        gpu_config="dofile(os.getenv(\"HOME\") .. \"/.config/hypr/nvidia.lua\")"
    fi
    
    # Interpolar template
    local content
    content=$(cat "${DOTFILES_DIR}/scripts/templates/host.lua")
    content="${content//\{\{HOSTNAME\}\}/$hostname}"
    content="${content//\{\{GPU_TYPE\}\}/$gpu_type}"
    content="${content//\{\{MONITOR_COUNT\}\}/$monitor_count}"
    content="${content//\{\{GPU_CONFIG\}\}/$gpu_config}"
    
    # Escribir archivo
    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "DRY RUN: Se escribiría en $target_file"
        echo "$content"
        return 0
    fi
    
    echo "$content" > "$target_file"
    log_success "Archivo de host generado"
}

# ─────────────────────────────────────────────────────────────
# Creación de symlinks
# ─────────────────────────────────────────────────────────────

safe_symlink() {
    local source="$1"
    local target="$2"
    local description="$3"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "DRY RUN: ln -s $source $target ($description)"
        return 0
    fi
    
    # Si target es un symlink existente que apunta a source, ok
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        log_success "$description ya está configurado"
        return 0
    fi
    
    # Si target existe y NO es un symlink
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        log_warn "$target ya existe y no es un symlink"
        if [ "$FORCE" -eq 0 ]; then
            if ! prompt_yes_no "¿Sobrescribir $target?"; then
                log_error "Cancelado por el usuario"
                return 1
            fi
        fi
        rm -rf "$target"
    fi
    
    # Crear el symlink
    mkdir -p "$(dirname "$target")"
    ln -sfn "$source" "$target"
    log_success "$description creado"
    return 0
}

create_symlinks() {
    log_section "Creando symlinks"
    
    safe_symlink "${DOTFILES_DIR}/hypr" "${CONFIG_DIR}/hypr" "Hyprland config" || return 1
    safe_symlink "${DOTFILES_DIR}/DankMaterialShell/settings.json" "${CONFIG_DIR}/DankMaterialShell/settings.json" "DMS settings" || return 1
    safe_symlink "${DOTFILES_DIR}/DankMaterialShell/themes" "${CONFIG_DIR}/DankMaterialShell/themes" "DMS themes" || return 1
    
    # Configurar systemd override para DMS (solo en Hyprland, no en GNOME)
    local dms_override_dir="${CONFIG_DIR}/systemd/user/dms.service.d"
    mkdir -p "$dms_override_dir"
    cat > "$dms_override_dir/hyprland-only.conf" << 'EOF'
[Unit]
# Solo iniciar DMS si estamos en Hyprland, no en GNOME
ConditionEnvironment=HYPRLAND_INSTANCE_SIGNATURE

[Service]
# Sin cambios - usar defaults
EOF
    log_success "Configuración systemd para DMS creada"
    
    log_success "Symlinks creados correctamente"
    return 0
}

# ─────────────────────────────────────────────────────────────
# Validación de instalación
# ─────────────────────────────────────────────────────────────

validate_installation() {
    log_info "Validando instalación..."
    
    if [ ! -L "${CONFIG_DIR}/hypr" ]; then
        log_error "Symlink de Hyprland no válido"
        return 1
    fi
    
    if [ ! -L "${CONFIG_DIR}/DankMaterialShell/settings.json" ]; then
        log_error "Symlink de DMS settings.json no válido"
        return 1
    fi
    
    if [ ! -L "${CONFIG_DIR}/DankMaterialShell/themes" ]; then
        log_error "Symlink de DMS themes no válido"
        return 1
    fi
    
    log_success "Instalación validada correctamente"
    return 0
}

# ─────────────────────────────────────────────────────────────
# Manejo de argumentos
# ─────────────────────────────────────────────────────────────

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --force)
                FORCE=1
                shift
                ;;
            --check)
                CHECK_ONLY=1
                shift
                ;;
            --restore-backup)
                RESTORE_BACKUP="$2"
                shift 2
                ;;
            *)
                echo "Opción desconocida: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

show_usage() {
    cat << 'EOF'
Uso: ./scripts/install.sh [OPTIONS]

Opciones:
  --check              Solo validar dependencias sin instalar
  --dry-run            Mostrar qué se haría sin ejecutar
  --force              Sobrescribir configuración existente
  --restore-backup <path>  Restaurar un backup anterior

Ejemplos:
  ./scripts/install.sh              # Instalación normal
  ./scripts/install.sh --check      # Solo validar
  ./scripts/install.sh --dry-run    # Previsualizar
  ./scripts/install.sh --force      # Forzar instalación
EOF
}

# ─────────────────────────────────────────────────────────────
# Flujo principal
# ─────────────────────────────────────────────────────────────

main() {
    parse_args "$@"
    
    # Inicializar log
    mkdir -p "$(dirname "$INSTALL_LOG")"
    log_section "Inicio de instalación de dotfiles"
    
    # Mostrar info del sistema
    local hostname=$(detect_hostname)
    local distro=$(detect_distro)
    local gpu=$(detect_gpu)
    local monitors=$(detect_monitors)
    
    log_info "Sistema: $distro | Hostname: $hostname | GPU: $gpu | Monitores: $monitors"
    
    # Modo restore backup
    if [ -n "$RESTORE_BACKUP" ]; then
        restore_backup "$RESTORE_BACKUP"
        exit $?
    fi
    
    # Validar herramientas básicas
    check_basic_deps || exit 1
    
    # Modo check-only
    if [ "$CHECK_ONLY" -eq 1 ]; then
        log_section "Validando dependencias (CHECK_ONLY)"
        check_hyprland_deps
        exit $?
    fi
    
    # Clonar repo si no existe
    if [ ! -d "${DOTFILES_DIR}/.git" ]; then
        log_error "No se encuentra repositorio git en ${DOTFILES_DIR}"
        exit 1
    fi
    
    # Detectar si ya está instalado
    local already_installed=0
    if [ -f "$INSTALL_STATE" ]; then
        already_installed=1
        log_info "Instalación anterior detectada"
    fi
    
    # Validar dependencias de Hyprland
    check_hyprland_deps || exit 1
    
    # Hacer backup si es necesario
    backup_existing_config
    
    # Generar archivo host dinámicamente
    generate_host_file "$hostname" "$gpu" "$monitors" || exit 1
    
    # Proponer configuración de monitores
    log_info "Detectados $monitors monitores"
    if [ "$monitors" -gt 0 ]; then
        if prompt_yes_no "¿Usar configuración propuesta para los monitores?"; then
            log_success "Usando configuración de monitores propuesta"
        else
            log_warn "Por favor edita manualmente: ${DOTFILES_DIR}/hypr/hosts/${hostname}.lua"
        fi
    fi
    
    # Crear symlinks
    create_symlinks || exit 1
    
    # Validar instalación
    validate_installation || exit 1
    
    # Guardar estado de instalación
    if [ "$DRY_RUN" -eq 0 ]; then
        mkdir -p "$(dirname "$INSTALL_STATE")"
        cat > "$INSTALL_STATE" << EOF
hostname=$hostname
gpu=$gpu
distro=$distro
installed_at=$(date)
EOF
        log_success "Estado de instalación guardado"
    fi
    
    log_section "Instalación completada exitosamente"
    log_info "Para recargar Hyprland: hyprctl reload"
    
    return 0
}

# Ejecutar main
main "$@"
