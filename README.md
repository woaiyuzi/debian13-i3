# Debian13 安装及配置过程

桌面使用`i3`

## 安装所有需要的程序

一次全部把基础程序安装，之后在进行配置

```bash
sudo apt install -y \
    xorg \
    xinit \
    i3-wm \
    fonts-jetbrains-mono \
    fonts-noto \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fcitx5 \
    fcitx5-chinese-addons \
    fcitx5-config-qt \
    fcitx5-frontend-all \
    im-config \
    i3status \
    rofi \
    dunst \
    alacritty \
    xclip \
    xdotool \
    xdg-utils \
    thunar \
    fish
```

## 配置输入法

```bash
im-config -n fcitx5

mkdir -p ~/.config/fcitx5

cat > ~/.config/fcitx5/profile <<'EOF'
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=pinyin

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=pinyin
Layout=

[GroupOrder]
0=Default
EOF
```

## 配置`i3`

先创建基础配置

```bash
mkdir -p ~/.config/i3

cat > ~/.config/i3/config <<'EOF'
# Mod 键：Windows/Super
set $mod Mod4

# 终端
set $term alacritty

# 启动器
set $menu rofi -show drun

# 启动终端
bindsym $mod+Return exec $term

# 启动 Rofi
bindsym $mod+d exec $menu

# 关闭窗口
bindsym $mod+Shift+q kill

# 重载配置
bindsym $mod+Shift+r reload

# 退出 i3
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'Exit i3?' -b 'Yes' 'i3-msg exit'"

# 窗口焦点
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

# 移动窗口
bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# 分割
bindsym $mod+b split h
bindsym $mod+Shift+v split v

# 全屏
bindsym $mod+f fullscreen toggle

# 浮动窗口
bindsym $mod+Shift+space floating toggle

# 工作区
set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"

bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4
bindsym $mod+5 workspace $ws5

# 移动窗口到工作区
bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4
bindsym $mod+Shift+5 move container to workspace $ws5

bar {
    status_command i3status
}

# 启动 dunst
exec --no-startup-id dunst

# Clipboard
exec --no-startup-id ~/.local/bin/clipboard-daemon
bindsym $mod+v exec --no-startup-id ~/.local/bin/clipboard-rofi

EOF
```

## 配置`i3status`

```bash
mkdir -p ~/.config/i3status

cat > ~/.config/i3status/config <<'EOF'
general {
    colors = true
    interval = 5
}

order += "wireless _first_"
order += "ethernet _first_"
order += "cpu_usage"
order += "memory"
order += "battery all"
order += "tztime local"

wireless _first_ {
    format_up = "W: %essid %quality"
    format_down = "W: down"
}

ethernet _first_ {
    format_up = "E: %ip"
    format_down = "E: down"
}

cpu_usage {
    format = "CPU: %usage"
}

memory {
    memory_used_method = "memavailable"
    format = "RAM: %used"
}

battery all {
    format = "BAT: %status %percentage %remaining"
}

tztime local {
    format = "%Y-%m-%d %H:%M"
}
EOF
```

PC电脑可以删除`wireless`和`battery`项

## 配置`dunst`

```bash
mkdir -p ~/.config/dunst

cat > ~/.config/dunst/dunstrc <<'EOF'
[global]
    # 右上角
    origin = top-right
    offset = 10x10

    # 尺寸
    width = 300
    height = 100
    notification_limit = 5

    # 外观
    font = Noto Sans 12
    padding = 8
    horizontal_padding = 8
    frame_width = 2
    corner_radius = 6

    # 内容
    format = "<b>%s</b>\n%b"

[urgency_low]
    background = "#222222"
    foreground = "#aaaaaa"
    timeout = 3


[urgency_normal]
    background = "#333333"
    foreground = "#ffffff"
    timeout = 5


[urgency_critical]
    background = "#8f0000"
    foreground = "#ffffff"
    timeout = 0
EOF
```

## 配置`rofi`

```bash
mkdir -p ~/.config/rofi

cat > ~/.config/rofi/config.rasi <<'EOF'
configuration {
    show-icons: true;
    drun-display-format: "{name}";
    font: "Noto Sans 12";
}


* {
    spacing: 5px;
    padding: 5px;
}

window {
    width: 40%;
    border: 1px;
    border-radius: 5px;
}

inputbar {
    padding: 8px;
}

listview {
    lines: 8;
}
EOF
```

## 配置`alacritty`

```bash
mkdir -p ~/.config/alacritty

cat > ~/.config/alacritty/alacritty.toml <<'EOF'
[font]
normal = { family = "JetBrains Mono", style = "Regular" }
bold = { family = "JetBrains Mono", style = "Bold" }
italic = { family = "JetBrains Mono", style = "Italic" }
bold_italic = { family = "JetBrains Mono", style = "Bold Italic" }

size = 12.0

[window]
padding = { x = 8, y = 8 }
dynamic_padding = true

[scrolling]
history = 10000

[colors.primary]
background = "#101418"
foreground = "#d8dee9"

[cursor]
style = "Block"
```

## 配置Clash Mi

去`github`下载`deb`安装

## 配置剪切板
```bash
mkdir -p ~/.local/bin
mkdir -p ~/.cache/i3-clipboard

wget -O ~/.local/bin/clipboard-daemon https://raw.githubusercontent.com/woaiyuzi/debian13-i3/refs/heads/main/clipboard-daemon

wget -O ~/.local/bin/clipboard-rofi https://raw.githubusercontent.com/woaiyuzi/debian13-i3/refs/heads/main/clipboard-rofi

chmod +x ~/.local/bin/clipboard-daemon
chmod +x ~/.local/bin/clipboard-rofi
```

## 配置helix

去`github`下载`deb`安装

## 配置fish

```bash
chsh -s /usr/bin/fish

mkdir -p ~/.config/fish

cat > ~/.config/fish/config.fish <<'EOF
# Editor
set -gx EDITOR hx

# PATH
fish_add_path ~/.local/bin

# Aliases
alias ll "ls -lah"
alias la "ls -A"
EOF
```

## 快捷键列表

> `Mod` = `Mod4`，即键盘上的 Windows / Super 键。

### 程序

| 快捷键 | 功能 |
|---|---|
| `Mod + Enter` | 打开 Alacritty 终端 |
| `Mod + D` | 打开 Rofi 程序启动器 |
| `Mod + V` | 打开剪切板历史 |

### 窗口管理

| 快捷键 | 功能 |
|---|---|
| `Mod + Shift + Q` | 关闭当前窗口 |
| `Mod + F` | 全屏切换 |
| `Mod + Shift + Space` | 浮动窗口切换 |

### 窗口焦点

| 快捷键 | 功能 |
|---|---|
| `Mod + H` | 焦点向左 |
| `Mod + J` | 焦点向下 |
| `Mod + K` | 焦点向上 |
| `Mod + L` | 焦点向右 |

### 移动窗口

| 快捷键 | 功能 |
|---|---|
| `Mod + Shift + H` | 向左移动当前窗口 |
| `Mod + Shift + J` | 向下移动当前窗口 |
| `Mod + Shift + K` | 向上移动当前窗口 |
| `Mod + Shift + L` | 向右移动当前窗口 |

### 窗口分割

| 快捷键 | 功能 |
|---|---|
| `Mod + B` | 水平分割 |
| `Mod + Shift + V` | 垂直分割 |

### 工作区

#### 切换工作区

| 快捷键 | 功能 |
|---|---|
| `Mod + 1` | 切换到工作区 1 |
| `Mod + 2` | 切换到工作区 2 |
| `Mod + 3` | 切换到工作区 3 |
| `Mod + 4` | 切换到工作区 4 |
| `Mod + 5` | 切换到工作区 5 |

#### 移动窗口到工作区

| 快捷键 | 功能 |
|---|---|
| `Mod + Shift + 1` | 将当前窗口移动到工作区 1 |
| `Mod + Shift + 2` | 将当前窗口移动到工作区 2 |
| `Mod + Shift + 3` | 将当前窗口移动到工作区 3 |
| `Mod + Shift + 4` | 将当前窗口移动到工作区 4 |
| `Mod + Shift + 5` | 将当前窗口移动到工作区 5 |

### i3 管理

| 快捷键 | 功能 |
|---|---|
| `Mod + Shift + R` | 重载配置 |
| `Mod + Shift + E` | 退出 i3 |

## nvidia-legacy-390xx-driver
```bash
wget -O ~/.local/bin/bi-nvidia-legacy-390xx-driver https://raw.githubusercontent.com/woaiyuzi/debian13-i3/refs/heads/main/bi-nvidia-legacy-390xx-driver

chmod +x ~/.local/bin/bi-nvidia-legacy-390xx-driverbi-nvidia-legacy-390xx-driver

bash ~/.local/bin/bi-nvidia-legacy-390xx-driver
```
