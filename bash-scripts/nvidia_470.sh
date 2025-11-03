#!/usr/bin/env bash
set -euo pipefail

### ——— helpers ———
msg() { printf "\n\033[1;32m➜ %s\033[0m\n" "$*"; }
warn() { printf "\n\033[1;33m⚠ %s\033[0m\n" "$*"; }
err() { printf "\n\033[1;31m✗ %s\033[0m\n" "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || { err "нужна команда: $1"; exit 1; }; }

err "Если черный экран, ./setup-nvidia470.sh --rollback && sudo reboot"

ROLLBACK_ONLY="${1:-}"

XORG_DIR="/etc/X11/xorg.conf.d"
PATH_CONF="$XORG_DIR/01-nvidia-path.conf"
DEV_CONF="$XORG_DIR/10-nvidia.conf"
MODPROBE_NOUVEAU="/etc/modprobe.d/blacklist-nouveau.conf"
MODPROBE_NVIDIA="/etc/modprobe.d/nvidia.conf"
GPU_NOTIFY="$HOME/.local/bin/gpu-notify.sh"
I3_CONFIG="$HOME/.config/i3/config"

### ——— rollback ———
rollback() {
  warn "Откат конфигурации Xorg/NVIDIA…"
  sudo rm -f "$PATH_CONF" || true
  sudo mv -f "$DEV_CONF" "$DEV_CONF.bak" 2>/dev/null || true
  sudo rm -f "$MODPROBE_NOUVEAU" || true
  # modeset оставим — он безопасен, но можно снять:
  # sudo rm -f "$MODPROBE_NVIDIA" || true
  sudo mkinitcpio -P || true
  msg "Откат выполнен. Перезагрузи систему: sudo reboot"
}

if [[ "$ROLLBACK_ONLY" == "--rollback" ]]; then
  rollback
  exit 0
fi

### ——— 0) базовые зависимости ———
msg "Обновляем систему и ставим базовые пакеты…"
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm base-devel git neovim vim wget curl

### ——— 1) yay ———
if ! command -v yay >/dev/null 2>&1; then
  msg "Устанавливаем yay (AUR helper)…"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  git -C "$tmpdir" clone https://aur.archlinux.org/yay.git
  ( cd "$tmpdir/yay" && makepkg -si --noconfirm )
else
  msg "yay уже установлен."
fi

### ——— 2) linux-headers для DKMS ———
msg "Ставим заголовки ядра для DKMS…"
# если на lts — поставь и lts headers; без паники, pacman сам разберётся
sudo pacman -S --needed --noconfirm linux-headers || true
[[ -d /usr/lib/modules/$(uname -r)/build ]] || warn "Путь /usr/lib/modules/$(uname -r)/build не найден. Если DKMS заругается, поставь подходящие headers вручную."

### ——— 3) драйверы NVIDIA 470xx ———
msg "Ставим драйверы NVIDIA 470xx (dkms/utils/lib32/settings)…"
yay -S --noconfirm --needed \
  nvidia-470xx-dkms nvidia-470xx-utils lib32-nvidia-470xx-utils nvidia-470xx-settings

### ——— 4) полезные утилиты ———
msg "Ставим полезные утилиты (mesa-utils, vulkan-tools, libnotify)…"
sudo pacman -S --needed --noconfirm mesa-utils vulkan-tools libnotify

### ——— 5) отключаем nouveau и включаем modeset ———
msg "Отключаем nouveau и включаем nvidia_drm modeset=1…"
echo 'blacklist nouveau'                 | sudo tee "$MODPROBE_NOUVEAU" >/dev/null
echo 'options nvidia_drm modeset=1'      | sudo tee "$MODPROBE_NVIDIA"  >/dev/null

### ——— 6) Xorg конфиги ———
msg "Генерируем конфиги Xorg…"
sudo mkdir -p "$XORG_DIR"

# Правильный путь к серверному GLX модулю NVIDIA (470xx кладёт в /usr/lib/nvidia/xorg)
sudo tee "$PATH_CONF" >/dev/null <<'CONF'
Section "Files"
    ModulePath "/usr/lib/nvidia/xorg"
    ModulePath "/usr/lib/xorg/modules"
EndSection
CONF

# Явный драйвер nvidia
sudo tee "$DEV_CONF" >/dev/null <<'CONF'
Section "Device"
    Identifier "NVIDIA Card"
    Driver "nvidia"
    VendorName "NVIDIA Corporation"
    Option "AllowEmptyInitialConfiguration"
EndSection
CONF

### ——— 7) initramfs ———
msg "Пересобираем initramfs…"
sudo mkinitcpio -P

### ——— 8) sanity-check: наличие libglxserver_nvidia.so ———
msg "Проверяем наличие серверного GLX модуля NVIDIA…"
if [[ ! -e /usr/lib/nvidia/xorg/libglxserver_nvidia.so ]]; then
  err "Не найден /usr/lib/nvidia/xorg/libglxserver_nvidia.so — utils не установлены корректно."
  echo "Проверь: yay -S nvidia-470xx-utils lib32-nvidia-470xx-utils"
  exit 1
fi

### ——— 9) GPU notifier для i3 (опционально) ———
msg "Создаём GPU notifier скрипт для i3…"
mkdir -p "$(dirname "$GPU_NOTIFY")"
cat > "$GPU_NOTIFY" <<'SH'
#!/usr/bin/env bash
set -e
renderer=$(glxinfo -B 2>/dev/null | awk -F': ' '/OpenGL renderer string/ {print $2}')
client=$(glxinfo -B 2>/dev/null | awk -F': ' '/client glx vendor string/ {print $2}')
server=$(glxinfo -B 2>/dev/null | awk -F': ' '/server glx vendor string/ {print $2}')
[ -n "$renderer" ] || renderer="unknown (glxinfo not available)"
body="Renderer: $renderer"
if [ -n "$client" ] && [ -n "$server" ]; then
  body="$body"$'\n'"GLX (client/server): $client / $server"
fi
notify-send -i video-card "GPU renderer" "$body"
SH
chmod +x "$GPU_NOTIFY"

# аккуратно добавим в i3/config, если он есть и строки ещё нет
if [[ -f "$I3_CONFIG" ]]; then
  if ! grep -q 'gpu-notify.sh' "$I3_CONFIG"; then
    msg "Добавляем автозапуск notifier в i3/config (с бэкапом)…"
    cp "$I3_CONFIG" "$I3_CONFIG.bak.$(date +%s)"
    printf "\nexec --no-startup-id bash -lc 'sleep 2; %q'\n" "$GPU_NOTIFY" >> "$I3_CONFIG"
  else
    warn "В i3/config уже есть автозапуск gpu-notify.sh — пропускаем."
  fi
else
  warn "i3/config не найден, пропускаем автодобавление. Добавь вручную при желании:"
  echo "  exec --no-startup-id bash -lc 'sleep 2; $GPU_NOTIFY'"
fi

### ——— 10) финальные подсказки ———
msg "Установка завершена. РЕКОМЕНДУЮ перезагрузиться сейчас: sudo reboot"
echo
echo "После входа в i3 проверьте:"
echo "  glxinfo -B | egrep 'vendor|string|renderer'"
echo "Ожидаемо: 'OpenGL renderer string: NVIDIA GeForce GT 710/PCIe/SSE2'"
echo
echo "Если вдруг не поднимется графика (чёрный экран) — войди в TTY и откати:"
echo "  $(basename "$0") --rollback"
