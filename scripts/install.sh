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
    [Nn]* | "") return 1 ;;
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
    hyprctl monitors 2>/dev/null | grep -c "^Monitor"
  else
    echo "0"
  fi
}

prepare_noctalia_host_config() {
  local hostname="$1"
  local noctalia_root="${DOTFILES_DIR}/noctalia"
  local host_dir="${noctalia_root}/machines/${hostname}"
  local source_dir="${CONFIG_DIR}/noctalia"

  if [ -d "$host_dir" ]; then
    return 0
  fi

  log_info "Preparando perfil de Noctalia para $hostname"
  mkdir -p "$host_dir"

  if [ -e "$source_dir" ]; then
    cp -aL "$source_dir/." "$host_dir/"
  else
    log_error "No existe una config fuente en $source_dir"
    log_error "Crea primero ~/.config/noctalia o copia un perfil existente a ${noctalia_root}/machines/${hostname}"
    return 1
  fi

  log_success "Perfil de Noctalia preparado en $host_dir"
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

  if [ ! -d "$CONFIG_DIR/hypr" ] && [ ! -d "$CONFIG_DIR/noctalia" ]; then
    log_info "No hay configuración anterior que respaldar"
    return 0
  fi

  log_info "Creando backup de configuración anterior..."
  mkdir -p "$backup_path"

  if [ -d "$CONFIG_DIR/hypr" ]; then
    cp -aL "$CONFIG_DIR/hypr" "$backup_path/" 2>/dev/null || true
    log_success "Backup de hypr creado"
  fi

  if [ -d "$CONFIG_DIR/noctalia" ]; then
    cp -aL "$CONFIG_DIR/noctalia" "$backup_path/" 2>/dev/null || true
    log_success "Backup de noctalia creado"
  fi

  echo "$backup_path"
}

restore_backup() {
  local backup_path="$1"
  local hostname
  hostname=$(detect_hostname)
  local noctalia_target="${DOTFILES_DIR}/noctalia/machines/${hostname}"

  if [ ! -d "$backup_path" ]; then
    log_error "Backup no encontrado: $backup_path"
    return 1
  fi

  log_warn "Restaurando backup desde: $backup_path"

  if [ -d "$backup_path/hypr" ]; then
    rm -rf "$DOTFILES_DIR/hypr"
    cp -r "$backup_path/hypr" "$DOTFILES_DIR/"
    log_success "Hypr restaurado"
  fi

  if [ -d "$backup_path/noctalia" ]; then
    rm -rf "$noctalia_target"
    mkdir -p "$(dirname "$noctalia_target")"
    cp -r "$backup_path/noctalia" "$noctalia_target"
    log_success "Noctalia restaurado"
  fi

  if [ -d "$DOTFILES_DIR/hypr" ]; then
    ln -sfn "$DOTFILES_DIR/hypr" "$CONFIG_DIR/hypr"
  fi

  if [ -d "$noctalia_target" ]; then
    # Eliminar ~/.config/noctalia (ahora se usa NOCTALIA_CONFIG_DIR en autostart.lua)
    rm -rf "${CONFIG_DIR}/noctalia"
  fi
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

  local hostname
  hostname=$(detect_hostname)
  prepare_noctalia_host_config "$hostname" || return 1

  safe_symlink "${DOTFILES_DIR}/hypr" "${CONFIG_DIR}/hypr" "Hyprland config" || return 1

  # Noctalia usa NOCTALIA_CONFIG_DIR (ver autostart.lua), no symlinks
  # Limpiar estructura antigua si existe
  if [ -L "${CONFIG_DIR}/noctalia" ]; then
    log_warn "Eliminando symlink antiguo de Noctalia: ${CONFIG_DIR}/noctalia"
    rm "${CONFIG_DIR}/noctalia"
  elif [ -d "${CONFIG_DIR}/noctalia" ]; then
    log_warn "Eliminando directorio antiguo de Noctalia: ${CONFIG_DIR}/noctalia"
    rm -rf "${CONFIG_DIR}/noctalia"
  fi

  log_success "Noctalia config: usa NOCTALIA_CONFIG_DIR -> ${DOTFILES_DIR}/noctalia/machines/${hostname}"
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

  if [ -d "${CONFIG_DIR}/noctalia" ] || [ -L "${CONFIG_DIR}/noctalia" ]; then
    log_warn "Eliminando ~/.config/noctalia (ahora se usa NOCTALIA_CONFIG_DIR)"
    rm -rf "${CONFIG_DIR}/noctalia"
  fi
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
  cat <<'EOF'
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
  if [ "$DRY_RUN" -eq 0 ]; then
    backup_existing_config
  else
    log_info "DRY RUN: se omiten backups"
  fi

  log_info "Detectados $monitors monitores"
  if [ "$monitors" -gt 0 ]; then
    log_info "La configuración de monitores se mantiene en ${DOTFILES_DIR}/hypr/hosts/${hostname}.lua"
  fi

  # Crear symlinks
  create_symlinks || exit 1

  # Validar instalación
  validate_installation || exit 1

  # Guardar estado de instalación
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$(dirname "$INSTALL_STATE")"
    cat >"$INSTALL_STATE" <<EOF
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
