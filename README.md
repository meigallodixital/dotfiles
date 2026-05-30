# dotfiles

Configuración personal del entorno de escritorio. Basado en **Hyprland** (Wayland) con **Noctalia** como shell.

## Estructura

```
~/.dotfiles/
├── hypr/               # Hyprland (compositor Wayland)
│   ├── hyprland.lua    # Config principal: layout, input, render
│   ├── theme.lua       # Colores y espaciados (editar aquí para cambiar el look)
│   ├── nvidia.lua      # Variables de entorno y ajustes específicos de NVIDIA
│   ├── animations.lua  # Curvas bezier y animaciones
│   ├── autostart.lua   # Aplicaciones que arrancan con la sesión
│   ├── binds.lua       # Atajos de teclado
│   ├── hosts/          # Config específica por máquina (monitor, GPU)
│   │   └── f5700x.lua  # Desktop — GPU NVIDIA
│   └── .luarc.json     # Declara globals de Hyprland para el LSP de Lua
└── noctalia/           # Noctalia shell
    ├── settings.json   # Ajustes generales
    ├── colors.json     # Paleta de colores activa
    ├── plugins.json    # Plugins habilitados
    ├── colorschemes/   # Esquemas de color adicionales
    └── plugins/        # Plugins instalados
```

## Instalación en una máquina nueva

```bash
git clone <repo> ~/.dotfiles

# Hyprland
ln -s ~/.dotfiles/hypr ~/.config/hypr

# Noctalia
ln -s ~/.dotfiles/noctalia ~/.config/noctalia
```

Después crear el fichero de host correspondiente:

```bash
cp ~/.dotfiles/hypr/hosts/f5700x.lua ~/.dotfiles/hypr/hosts/$(hostname).lua
# Editar el nuevo fichero con la config de monitor y GPU de la máquina
```

## Añadir una nueva máquina

1. Crear `hypr/hosts/<hostname>.lua` con la configuración de monitor y GPU
2. Si la máquina tiene NVIDIA, añadir `dofile(...nvidia.lua)` al final del fichero de host
3. Commit y push

## Cambiar el tema visual

Editar `hypr/theme.lua` y recargar Hyprland:

```bash
hyprctl reload
```

## Aplicaciones requeridas

| App | Descripción |
|---|---|
| `hyprland` | Compositor Wayland |
| `noctalia` | Shell de escritorio |
| `foot` | Terminal |
| `wofi` | Lanzador de aplicaciones |
