# dotfiles

Configuración personal del entorno de escritorio. Basado en **Hyprland** (Wayland) con **DMS (DankMaterialShell)** como shell.

## Estructura

```
~/.dotfiles/
├── scripts/
│   ├── install.sh              # Script de instalación idempotente
│   └── templates/
│       └── host.conf           # Template para generar configuración por máquina
├── hypr/                        # Hyprland (compositor Wayland)
│   ├── hyprland.conf           # Config principal: layout, input, render
│   ├── theme.conf              # Colores y espaciados (editar aquí para cambiar el look)
│   ├── nvidia.conf             # Variables de entorno y ajustes específicos de NVIDIA
│   ├── animations.conf         # Curvas bezier y animaciones
│   ├── autostart.conf          # Aplicaciones que arrancan con la sesión
│   ├── binds.conf              # Atajos de teclado
│   ├── dms/                    # Generado por DMS en runtime, ignorado por git
│   ├── hosts/                  # Config específica por máquina (monitor, GPU)
│   │   ├── current.conf        # Host activo cargado por hyprland.conf
│   │   └── <hostname>.conf     # Copia por máquina generada automáticamente
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
cp ~/.dotfiles/hypr/hosts/f5700x.conf ~/.dotfiles/hypr/hosts/current.conf
# Editar el fichero con la config de monitor y GPU de tu máquina
```

## Hyprland y DMS

La configuración activa de Hyprland usa el formato clásico `hyprland.conf`. No se mantiene configuración Lua porque DMS llama a Hyprland con dispatch clásico, por ejemplo `workspace 2`; con la API Lua de Hyprland 0.55 esa llamada falla con un error de sintaxis Lua y los botones de workspace de DMS dejan de funcionar.

`render.xp_mode` debe estar desactivado. DMS dibuja el fondo como una capa Wayland `background`; `xp_mode = true` puede impedir que esa capa se vea y rompe el cambio de fondo desde DMS. El instalador lo valida en `--check`.

Es importante que no exista `~/.config/hypr/hyprland.lua`, porque Hyprland 0.55 prioriza el modo Lua si ese fichero está presente.

Si la sesión ya estaba iniciada en modo Lua, `hyprctl reload` no cambia el proveedor de configuración. Hay que cerrar la sesión de Hyprland y volver a entrar para que `hyprctl systeminfo` deje de mostrar `configProvider: lua` y `hyprctl dispatch workspace 2` vuelva a aceptar la sintaxis clásica.

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

### Arranque real de DMS en Hyprland

DMS arranca como servicio de usuario de systemd. No debe arrancarse desde `hypr/autostart.conf` con `exec-once`, porque eso deja procesos fuera de systemd y puede provocar el error de Quickshell `An instance of this configuration is already running`.

La unidad activa está en:

```
~/.config/systemd/user/dms.service
```

La unidad está habilitada en `default.target`, no solo en `graphical-session.target`:

```ini
[Install]
WantedBy=graphical-session.target
WantedBy=default.target
```

Motivo: en esta instalación `graphical-session.target` puede aparecer inactivo aunque Hyprland esté funcionando. Si DMS depende solo de ese target, systemd no llega ni a intentar arrancarlo tras iniciar sesión.

Para evitar que DMS arranque antes que Hyprland, la unidad espera a que exista un proceso real `Hyprland`:

```ini
[Service]
Type=dbus
BusName=org.freedesktop.Notifications
ExecStartPre=/usr/bin/sh -c 'for i in $(seq 1 50); do /usr/bin/pgrep -xu "$USER" Hyprland >/dev/null && exit 0; sleep 0.2; done; exit 1'
ExecStart=/usr/bin/dms run --session
```

No usar `ConditionEnvironment=HYPRLAND_INSTANCE_SIGNATURE` como filtro principal: el entorno de `systemd --user` puede conservar variables antiguas de Hyprland incluso estando en GNOME, así que no es una señal fiable.

Si DMS no aparece tras entrar en Hyprland, comprobar:

```bash
systemctl --user status dms.service
journalctl --user -u dms.service -b
pgrep -ax dms
pgrep -ax qs
```

Si el log muestra `An instance of this configuration is already running`, hay una instancia antigua de `dms`/`qs` fuera del servicio. Hay que pararla y volver a arrancar el servicio:

```bash
systemctl --user restart dms.service
```

Si eso no basta, localizar la instancia huérfana con `pgrep -ax dms; pgrep -ax qs` y terminar solo esos procesos antes de arrancar de nuevo `dms.service`.

### NVIDIA y cursor

En NVIDIA 595 con Hyprland 0.55, `cursor.no_hardware_cursors = 1` provocaba pantalla negra con doble cursor, uno móvil y otro congelado. La configuración real usa cursor hardware:

```conf
cursor {
    no_hardware_cursors = 0
}
```

Esto está en `hypr/nvidia.conf`.

### Ficheros generados por DMS en Hyprland

DMS puede escribir ficheros bajo `~/.config/hypr/dms/`, por ejemplo:

```text
~/.config/hypr/dms/colors.conf
~/.config/hypr/dms/layout.conf
~/.config/hypr/dms/windowrules.conf
```

Como `~/.config/hypr` apunta a `~/.dotfiles/hypr`, esos ficheros aparecen dentro del repo local. Son artefactos generados en runtime por DMS y no deben versionarse. Por eso `.gitignore` ignora `hypr/dms/`.

## Cambiar el tema visual

Editar `hypr/theme.conf` y recargar Hyprland:

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
cp ~/.dotfiles/scripts/templates/host.conf ~/.dotfiles/hypr/hosts/current.conf
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
