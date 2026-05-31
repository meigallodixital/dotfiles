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
    
    for cmd in git ln mkdir systemctl pgrep; do
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
    
    for cmd in hyprland hyprctl hyprshot dms; do
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

    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "DRY RUN: se crearía backup en $backup_path"
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
# Generación dinámica de host.conf
# ─────────────────────────────────────────────────────────────

generate_host_file() {
    local hostname="$1"
    local gpu_type="$2"
    local monitor_count="$3"
    local target_file="${DOTFILES_DIR}/hypr/hosts/current.conf"
    local host_file="${DOTFILES_DIR}/hypr/hosts/${hostname}.conf"
    
    log_info "Generando archivo de host: $target_file"
    
    # Determinar configuración de GPU
    local gpu_config=""
    if [ "$gpu_type" = "NVIDIA" ]; then
        gpu_config="source = ~/.config/hypr/nvidia.conf"
    fi
    
    # Interpolar template
    local content
    content=$(cat "${DOTFILES_DIR}/scripts/templates/host.conf")
    content="${content//\{\{HOSTNAME\}\}/$hostname}"
    content="${content//\{\{GPU_TYPE\}\}/$gpu_type}"
    content="${content//\{\{MONITOR_COUNT\}\}/$monitor_count}"
    content="${content//\{\{GPU_CONFIG\}\}/$gpu_config}"
    
    # Escribir archivo
    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "DRY RUN: Se escribiría en $target_file"
        log_info "DRY RUN: Se escribiría copia por hostname en $host_file"
        echo "$content"
        return 0
    fi
    
    echo "$content" > "$target_file"
    echo "$content" > "$host_file"
    log_success "Archivo de host generado"
}

validate_hyprland_config_files() {
    local hypr_config_dir="$1"

    if [ ! -f "${hypr_config_dir}/hyprland.conf" ]; then
        log_error "No existe hyprland.conf clásico"
        return 1
    fi

    if [ -f "${hypr_config_dir}/hyprland.lua" ]; then
        log_error "Existe hyprland.lua en la raíz; Hyprland arrancaría en modo Lua"
        return 1
    fi

    if ! grep -q "source = ~/.config/hypr/hosts/current.conf" "${hypr_config_dir}/hyprland.conf"; then
        log_error "hyprland.conf no carga hosts/current.conf"
        return 1
    fi

    if [ ! -f "${hypr_config_dir}/hosts/current.conf" ]; then
        log_error "No existe configuración de host activa: ${hypr_config_dir}/hosts/current.conf"
        return 1
    fi

    if grep -Eq "^[[:space:]]*xp_mode[[:space:]]*=[[:space:]]*true" "${hypr_config_dir}/hyprland.conf"; then
        log_error "render.xp_mode=true rompe el fondo de DMS"
        return 1
    fi

    if ! grep -Eq "^[[:space:]]*xp_mode[[:space:]]*=[[:space:]]*false" "${hypr_config_dir}/hyprland.conf"; then
        log_warn "No se encontró render.xp_mode=false; DMS puede no mostrar el fondo"
    fi

    return 0
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
    
    local hostname=$(detect_hostname)
    
    safe_symlink "${DOTFILES_DIR}/hypr" "${CONFIG_DIR}/hypr" "Hyprland config" || return 1
    
    # DMS settings.json por máquina
    local dms_settings_dotfiles="${DOTFILES_DIR}/DankMaterialShell/settings-${hostname}.json"
    local dms_settings_config="${CONFIG_DIR}/DankMaterialShell/settings.json"
    
    # Si settings-<hostname>.json no existe en dotfiles, copiar desde config
    if [ ! -f "$dms_settings_dotfiles" ]; then
        if [ -f "$dms_settings_config" ]; then
            log_info "Copiando settings.json de esta máquina a dotfiles con nombre de hostname..."
            mkdir -p "$(dirname "$dms_settings_dotfiles")"
            cp "$dms_settings_config" "$dms_settings_dotfiles"
            log_success "Settings guardado como settings-${hostname}.json"
        else
            log_warn "No se encontró settings.json en $dms_settings_config"
        fi
    fi
    
    # Crear symlink de config a dotfiles
    safe_symlink "$dms_settings_dotfiles" "$dms_settings_config" "DMS settings (${hostname})" || return 1
    
    # DMS themes (compartido, global)
    safe_symlink "${DOTFILES_DIR}/DankMaterialShell/themes" "${CONFIG_DIR}/DankMaterialShell/themes" "DMS themes" || return 1
    
    configure_dms_systemd || return 1
    
    log_success "Symlinks creados correctamente"
    return 0
}

configure_dms_systemd() {
    log_info "Configurando DMS como servicio systemd de usuario..."

    local systemd_user_dir="${CONFIG_DIR}/systemd/user"
    local dms_service="${systemd_user_dir}/dms.service"
    local dms_override_dir="${systemd_user_dir}/dms.service.d"
    local dms_override="${dms_override_dir}/hyprland-only.conf"

    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "DRY RUN: se escribiría $dms_service"
        log_info "DRY RUN: se escribiría $dms_override"
        log_info "DRY RUN: systemctl --user daemon-reload && systemctl --user enable dms.service"
        return 0
    fi

    mkdir -p "$systemd_user_dir" "$dms_override_dir"

    cat > "$dms_service" << 'EOF'
[Unit]
Description=Dank Material Shell (DMS)
PartOf=graphical-session.target

[Service]
Type=dbus
BusName=org.freedesktop.Notifications
ExecStartPre=/usr/bin/sh -c 'for i in $(seq 1 50); do /usr/bin/pgrep -xu "$USER" Hyprland >/dev/null && exit 0; sleep 0.2; done; exit 1'
ExecStart=/usr/bin/dms run --session
ExecReload=/usr/bin/pkill -USR1 -x dms
Restart=on-failure
RestartSec=1.23
TimeoutStopSec=10

[Install]
WantedBy=graphical-session.target
WantedBy=default.target
EOF

    cat > "$dms_override" << 'EOF'
[Unit]
# ConditionEnvironment no es fiable aquí: el entorno de systemd --user puede
# conservar variables antiguas de Hyprland incluso estando en GNOME.
ConditionEnvironment=
# En esta sesión Hyprland puede seguir vivo aunque graphical-session.target
# aparezca inactivo; no debe bloquear el arranque de DMS.
Requisite=
After=

[Service]
# La unidad principal espera a que Hyprland exista antes de arrancar DMS.
ExecCondition=
EOF

    systemctl --user daemon-reload || {
        log_error "No se pudo recargar systemd --user"
        return 1
    }

    systemctl --user enable dms.service || {
        log_error "No se pudo habilitar dms.service"
        return 1
    }

    log_success "DMS configurado como servicio systemd de usuario"
    return 0
}

# ─────────────────────────────────────────────────────────────
# Validación de instalación
# ─────────────────────────────────────────────────────────────

validate_installation() {
    log_info "Validando instalación..."
    
    local hostname=$(detect_hostname)
    
    if [ ! -L "${CONFIG_DIR}/hypr" ]; then
        log_error "Symlink de Hyprland no válido"
        return 1
    fi

    validate_hyprland_config_files "${CONFIG_DIR}/hypr" || return 1
    
    if [ ! -L "${CONFIG_DIR}/DankMaterialShell/settings.json" ]; then
        log_error "Symlink de DMS settings.json no válido"
        return 1
    fi
    
    if [ ! -L "${CONFIG_DIR}/DankMaterialShell/themes" ]; then
        log_error "Symlink de DMS themes no válido"
        return 1
    fi
    
    # Verificar que settings.json apunta al archivo correcto de hostname
    local expected_target="${DOTFILES_DIR}/DankMaterialShell/settings-${hostname}.json"
    local actual_target=$(readlink "${CONFIG_DIR}/DankMaterialShell/settings.json" 2>/dev/null)
    
    if [ "$actual_target" != "$expected_target" ]; then
        log_error "Symlink de settings.json apunta a $actual_target, debería apuntar a $expected_target"
        return 1
    fi

    if [ ! -f "${CONFIG_DIR}/systemd/user/dms.service" ]; then
        log_error "No existe la unidad de usuario de DMS"
        return 1
    fi

    if [ ! -L "${CONFIG_DIR}/systemd/user/default.target.wants/dms.service" ]; then
        log_error "DMS no está habilitado en default.target"
        return 1
    fi

    if grep -q "ConditionEnvironment=HYPRLAND_INSTANCE_SIGNATURE" "${CONFIG_DIR}/systemd/user/dms.service" "${CONFIG_DIR}/systemd/user/dms.service.d/hyprland-only.conf" 2>/dev/null; then
        log_error "DMS conserva la condición obsoleta HYPRLAND_INSTANCE_SIGNATURE"
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
        deps_status=$?
        validate_hyprland_config_files "${DOTFILES_DIR}/hypr"
        config_status=$?
        if [ "$deps_status" -ne 0 ] || [ "$config_status" -ne 0 ]; then
            exit 1
        fi
        exit 0
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
            log_warn "Por favor edita manualmente: ${DOTFILES_DIR}/hypr/hosts/current.conf"
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
