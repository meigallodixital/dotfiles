# dotfiles

Configuración personal del entorno de escritorio. Basado en **Hyprland** (Wayland) con **DMS (DankMaterialShell)** como shell.

## Estructura

```
~/.dotfiles/
├── scripts/
│   ├── install.sh              # Script de instalación idempotente
│   └── templates/
│       └── host.lua            # Template para generar configuración por máquina
├── hypr/                        # Hyprland (compositor Wayland)
│   ├── hyprland.lua            # Config principal: layout, input, render
│   ├── theme.lua               # Colores y espaciados (editar aquí para cambiar el look)
│   ├── nvidia.lua              # Variables de entorno y ajustes específicos de NVIDIA
│   ├── animations.lua          # Curvas bezier y animaciones
│   ├── autostart.lua           # Aplicaciones que arrancan con la sesión
│   ├── binds.lua               # Atajos de teclado
│   ├── hosts/                  # Config específica por máquina (monitor, GPU)
│   │   └── <hostname>.lua      # Generados automáticamente por el script
│   └── .luarc.json             # Declara globals de Hyprland para el LSP de Lua
├── DankMaterialShell/           # DMS (DankMaterialShell) configuración versionada
│   ├── settings-f5700x.json    # Configuración de esta máquina (por hostname)
│   ├── settings-<hostname>.json # Configuración de otras máquinas
│   └── themes/                 # Temas personalizados (compartido global)
│       └── catppuccin/         # Ejemplo: tema Catppuccin
└── .gitignore
```

## Instalación en una máquina nueva

### Requisitos previos

Instalar DMS en tu sistema:

```bash
# Fedora 41+
sudo dnf copr enable avengemedia/dms -y
sudo dnf install dms -y

# Arch
sudo pacman -S dms-shell

# Debian/Ubuntu
sudo add-apt-repository ppa:avengemedia/danklinux
sudo add-apt-repository ppa:avengemedia/dms
sudo apt update && sudo apt install dms

# Compilar desde fuente
git clone https://github.com/AvengeMedia/DankMaterialShell.git ~/dms
cd ~/dms && sudo make install
```

### Opción 1: Automática (recomendado)

```bash
git clone <repo> ~/.dotfiles
cd ~/.dotfiles
./scripts/install.sh
```

El script se encargará de:

1. Detectar tu hardware (GPU, monitores)
2. Validar que tengas las dependencias instaladas
3. Generar la configuración específica de tu máquina
4. Crear los symlinks automáticamente
5. Hacer backup de cualquier configuración anterior
6. Configurar DMS para que se inicie con Hyprland

### Opción 2: Manual

Si prefieres hacer todo manualmente o el script tiene problemas:

```bash
git clone <repo> ~/.dotfiles

# Crear symlinks
ln -s ~/.dotfiles/hypr ~/.config/hypr

# Generar el archivo de host específico de tu máquina
cp ~/.dotfiles/hypr/hosts/f5700x.lua ~/.dotfiles/hypr/hosts/$(hostname).lua
# Editar el fichero con la config de monitor y GPU de tu máquina
```

## Uso del Script de Instalación

### Modos de operación

```bash
# Instalación normal (recomendado para máquinas nuevas)
./scripts/install.sh

# Solo validar dependencias sin instalar
./scripts/install.sh --check

# Previsualizar qué se haría (dry run)
./scripts/install.sh --dry-run

# Forzar sobrescritura de configuración existente
./scripts/install.sh --force

# Restaurar un backup anterior
./scripts/install.sh --restore-backup ~/.dotfiles/.backups/2026-05-30_14-30-45
```

### Idempotencia

El script es **idempotente**, lo que significa que:

- Puede ejecutarse múltiples veces sin problemas
- Detecta si ya está instalado
- Solo hace cambios si algo ha cambiado
- Hace backups automáticos antes de cambiar configuración
- Los backups se guardan en `~/.dotfiles/.backups/`

### Logs y Debugging

Los logs de cada ejecución se guardan en:

```
~/.dotfiles/.install.log
```

## Atajos de teclado (Hyprland)

### Aplicaciones

| Atajo | Acción |
|-------|--------|
| `Super + Return` | Abre kitty (terminal) |
| `Super + T` | Abre kitty (terminal, alternativo) |
| `Super + R` | Abre launcher de DMS |
| `Super + Shift + R` | Abre wofi (launcher alternativo) |

### Ventanas

| Atajo | Acción |
|-------|--------|
| `Super + Q` | Cierra ventana |
| `Super + F` | Fullscreen |
| `Super + V` | Toggle ventana flotante |
| `Super + M` | Salir de sesión |

### Navegación

| Atajo | Acción |
|-------|--------|
| `Super + H/L/K/J` | Navegar entre ventanas (izq/der/arriba/abajo) |
| `Super + Flechas` | Navegar entre ventanas (alternativo) |
| `Super + 1-9` | Ir a workspace 1-9 |
| `Super + Ctrl + Shift + Flechas` | Cambiar workspace |

### Mover ventanas

| Atajo | Acción |
|-------|--------|
| `Super + Shift + H/L/K/J` | Mover ventana (izq/der/arriba/abajo) |
| `Super + Shift + Flechas` | Mover ventana (alternativo) |
| `Super + Shift + 1-9` | Mover ventana a workspace 1-9 |
| `Super + Ctrl + Flechas` | Mover ventana con workspace |

### Capturas de pantalla

| Atajo | Acción |
|-------|--------|
| `Print` | Captura pantalla completa |
| `Super + Print` | Captura ventana activa |
| `Super + Shift + Print` | Captura región seleccionada |

## Configuración de DMS (DankMaterialShell)

DMS se inicia automáticamente al entrar en Hyprland mediante systemd. **GNOME no se ve afectado** — DMS solo corre en Hyprland.

### Versionado de configuración

La configuración de DMS se versionea en `~/.dotfiles/DankMaterialShell/`:

```
~/.dotfiles/DankMaterialShell/
├── settings-f5700x.json        # Configuración de esta máquina (por hostname)
├── settings-<hostname>.json    # Configuración de otras máquinas
└── themes/                     # Temas personalizados (compartido global)
    └── catppuccin/             # Ejemplo: tema Catppuccin
```

**Importante: `settings.json` es específico por máquina**

Cada máquina versionea su propia configuración de DMS:
- En **f5700x**: `settings-f5700x.json`
- En **otra-maquina**: `settings-otra-maquina.json`

Los temas en `themes/` son compartidos entre todas las máquinas.

### Symlinks automáticos

El instalador crea automáticamente:
- `~/.config/DankMaterialShell/settings.json` → `~/.dotfiles/DankMaterialShell/settings-<hostname>.json` (específico de la máquina)
- `~/.config/DankMaterialShell/themes` → `~/.dotfiles/DankMaterialShell/themes` (global)

Cuando cambias configuración en el GUI de DMS:
1. DMS actualiza `~/.config/DankMaterialShell/settings.json`
2. El symlink hace que se escriba en `~/.dotfiles/DankMaterialShell/settings-<hostname>.json`
3. Los cambios se versionan automáticamente en git (solo de tu máquina)

### Cambiar tema en DMS

La manera recomendada es usar el GUI de DMS:
- Abre DMS (Super + R)
- Ve a Configuración → Tema/Colores
- Selecciona tema y aplica

Los cambios se guardan automáticamente en `settings.json` y se versionan.

### Integración con systemd

DMS se gestiona via systemd de usuario:

```bash
# Ver estado
systemctl --user status dms

# Ver logs
journalctl --user -u dms -f

# Reiniciar DMS
systemctl --user restart dms

# Ver info del sistema y DMS
dms doctor
```

### ¿Por qué solo en Hyprland?

DMS está configurado con una condición systemd en:

```
~/.config/systemd/user/dms.service.d/hyprland-only.conf

[Unit]
ConditionEnvironment=HYPRLAND_INSTANCE_SIGNATURE

[Service]
# Sin cambios - usar defaults
```

Esto significa que DMS **solo se inicia si está establecida la variable `HYPRLAND_INSTANCE_SIGNATURE`**, que solo existe cuando ejecutas Hyprland. GNOME no tendrá esta variable, así que DMS nunca se iniciará en GNOME.

## Cambiar el tema visual

Editar `hypr/theme.lua` y recargar Hyprland:

```bash
hyprctl reload
```

## Añadir una nueva máquina

El script genera automáticamente el archivo host cuando se ejecuta por primera vez. Solo necesitas ejecutar:

```bash
~/.dotfiles/scripts/install.sh
```

Si necesitas regenerar la configuración:

```bash
cp ~/.dotfiles/scripts/templates/host.lua ~/.dotfiles/hypr/hosts/$(hostname).lua
# Editar según sea necesario
```

## Dependencias requeridas

El script validará automáticamente estas dependencias:

| Herramienta | Descripción | Obligatoria |
|---|---|---|
| `hyprland` | Compositor Wayland | Sí |
| `hyprctl` | Control de Hyprland | Sí |
| `hyprshot` | Capturas de pantalla | Sí |
| `dms` | DankMaterialShell - Shell de escritorio | Sí |
| `kitty` | Terminal | No (recomendada) |
| `wofi` | Lanzador de aplicaciones | No (recomendada) |
| `dgop` | Monitor de recursos para DMS | No (recomendada) |
| `matugen` | Generador de temas Material para DMS | No (recomendada) |

En Fedora, instalar todo de una vez:

```bash
sudo dnf install hyprland hyprshot dms kitty wofi dgop matugen
```

## Actualizar la configuración

Para traer cambios del repositorio:

```bash
cd ~/.dotfiles
git pull
./scripts/install.sh
```

El script detectará cambios y actualizará solo lo necesario.

## Restaurar desde backup

Si algo sale mal, restaurar fácilmente:

```bash
./scripts/install.sh --restore-backup ~/.dotfiles/.backups/YYYY-MM-DD_HH-MM-SS
```

## Configuración local (no versionada)

Cada máquina puede tener configuración local que no se versiona. Esto incluye:

- `.install-state` — Estado de la instalación anterior
- `.install.log` — Logs de instalaciones
- `.backups/` — Backups automáticos de configuración anterior

Estos archivos se ignoran automáticamente y no aparecen en `git status`.

## Referentes

- [Hyprland](https://hyprland.org) — Compositor Wayland
- [DankMaterialShell](https://danklinux.com) — Shell de escritorio moderno basado en Quickshell
- [Material Design 3](https://m3.material.io) — Sistema de diseño de Google
