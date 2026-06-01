# dotfiles

Configuración personal del entorno de escritorio. Basado en **Hyprland** (Wayland) con **Noctalia** como shell.

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
│   │   └── <hostname>.lua      # Archivo por máquina
│   └── .luarc.json             # Declara globals de Hyprland para el LSP de Lua
└── noctalia/                    # Noctalia shell
    ├── machines/
    │   ├── f5700x/             # Perfil completo de la máquina f5700x
    │   │   ├── settings.json
    │   │   ├── colors.json
    │   │   ├── plugins.json
    │   │   ├── colorschemes/
    │   │   └── plugins/
    │   └── msi-work/           # Perfil completo de la máquina msi-work
    │       ├── settings.json
    │       ├── colors.json
    │       ├── plugins.json
    │       ├── colorschemes/
    │       └── plugins/
    └── (symlink local) ~/.config/noctalia -> ~/.dotfiles/noctalia/machines/<hostname>
```

## Instalación en una máquina nueva

### Opción 1: Automática (recomendado)

```bash
git clone <repo> ~/.dotfiles
cd ~/.dotfiles
./scripts/install.sh
```

El script se encargará de:
1. Detectar tu hardware (GPU, monitores)
2. Validar que tengas las dependencias instaladas
3. Crear o preparar el perfil de Noctalia de tu máquina
4. Crear los symlinks automáticamente
5. Hacer backup de cualquier configuración anterior

### Opción 2: Manual

Si prefieres hacer todo manualmente o el script tiene problemas:

```bash
git clone <repo> ~/.dotfiles

# Crear symlinks
ln -s ~/.dotfiles/hypr ~/.config/hypr
ln -s ~/.dotfiles/noctalia/machines/$(hostname) ~/.config/noctalia

# Editar el perfil de Noctalia de tu máquina
# ~/.dotfiles/noctalia/machines/$(hostname)/
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
| `Super + R` | Abre launcher de Noctalia |
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
| `noctalia` | Shell de escritorio | Sí |
| `kitty` | Terminal | No (recomendada) |
| `wofi` | Lanzador de aplicaciones | No (recomendada) |

En Fedora, instalar todo de una vez:

```bash
sudo dnf install hyprland hyprshot noctalia kitty wofi
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
- [Noctalia](https://github.com/anomalyco/noctalia) — Shell de escritorio
