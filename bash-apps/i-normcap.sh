#! /bin/bash

cd ~/Downloads

sudo apt install -y build-essential tesseract-ocr tesseract-ocr-eng libtesseract-dev libleptonica-dev wl-clipboard
wget https://github.com/dynobo/normcap/releases/download/v0.5.4/NormCap-0.5.4-x86_64.AppImage
mv NormCap-0.5.4-x86_64.AppImage ~/.local/bin
chmod +x ~/.local/bin/NormCap-0.5.4-x86_64.AppImage

app_path=~/.local/share/applications/normcap.desktop
if [ ! -f "$app_path" ]; then
  touch "$app_path"
fi

image_address="https://dynobo.github.io/normcap/assets/normcap.svg"
wget -O ~/.local/share/icons/normcap.svg "$image_address"

cat <<TEST >> "$app_path"
[Desktop Entry]
Version=1.0
Name=Normcap
Comment=Start Normcap
Exec=~/.local/bin/NormCap-0.5.4-x86_64.AppImage
Icon=~/.local/share/icons/normcap.svg
Terminal=true
Type=Application
TEST
