#!/bin/bash

clear
echo "Instalando dependências..."
echo "🔍 Verificando arquitetura do sistema..."
MACHINE_TYPE=$(uname -m)

if [ "$MACHINE_TYPE" == "x86_64" ]; then
    echo "✔️ Sistema 64 bits detectado. Ativando suporte à arquitetura i386..."
    dpkg --print-foreign-architectures | grep -q i386 || sudo dpkg --add-architecture i386
else
    echo "✔️ Sistema 32 bits detectado. Não é necessário ativar suporte i386."
fi

echo "🔄 Atualizando listas de pacotes..."
sudo apt-get update

echo "🧩 Corrigindo dependências pendentes..."
sudo apt-get -f install -y

    # Lista unificada de bibliotecas necessárias
    LIBS=(
        "libxtst6:i386"
        "libxtst6"
        "libstdc++6:i386"
        "libstdc++6"
        "lib32stdc++6"
        "libusb-0.1:i386"
        "libusb-0.1-4:i386"
        "libusb-1.0-0:i386"
        "libgtk2.0-0:i386"
        "libcrypt1:i386"
        "libxml2:i386"
        "gtk2-engines:i386"
        "libcanberra-gtk-module:i386"
        "sqlite3:i386"
        "mc"
        "htop"
        "wget"
        "net-tools"
        "setserial"
    )

    echo "📦 Verificando e instalando bibliotecas necessárias..."
    for lib in "${LIBS[@]}"; do
        if dpkg -s "$lib" &>/dev/null; then
            echo "✔️ $lib já está instalado."
        else
            echo "➡️ Instalando $lib..."
            sudo apt-get install -y --allow-downgrades --allow-change-held-packages --allow-remove-essential "$lib" || {
                echo "⚠️ Erro ao instalar $lib. Tentando forçar com dpkg..."
                            apt-get download "$lib" && sudo dpkg -i --force-overwrite "$lib*.deb"
                        }
        fi
    done

    echo "🧹 Finalizando instalação e corrigindo dependências..."
    sudo apt-get -f install -y

    echo "✅ Bibliotecas verificadas e instaladas com sucesso!"

    echo "Instalando TeamViewer"
    wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb 
    sudo dpkg -i teamviewer_amd64.deb
    echo "teamviewer instalado"

    echo "Instalando Anydesk"
    wget https://download.anydesk.com/linux/anydesk_7.0.0-1_amd64.deb -O anydesk.deb
    sudo dpkg -i anydesk.deb
    sudo apt-get install -f
    echo "AnyDesk instalado"

    echo "Instalando putty/screen"
    sudo apt-get install -y putty screen
    sudo usermod -a -G dialout rpdv
    echo "Putty instalado"

    echo "Instalando numlockx"
    sudo apt install -y numlockx
    UsuarioReal=$(logname)
    AutostartDir="/home/$UsuarioReal/.config/autostart"
    DesktopFile="$AutostartDir/numlockx.desktop"

        # Cria o diretório de autostart, se necessário
        mkdir -p "$AutostartDir"

        # Cria o arquivo .desktop se ele ainda não existir
        if [ -f "$DesktopFile" ]; then
            echo "O arquivo $DesktopFile já existe. Não será recriado."
        else
            cat <<EOL > "$DesktopFile"
[Desktop Entry]
Type=Application
Exec=numlockx on
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=NumLockX
Comment=Enable NumLock at startup
EOL
        fi
        chown "$UsuarioReal:$UsuarioReal" "$DesktopFile"
        echo "Arquivo de inicialização automática criado com sucesso: $DesktopFile"
        echo "Numlockx instalado"

        echo "Instalando VNC"

        sudo apt update
        sudo apt install -y x11vnc

        # Cria serviço systemd
        sudo cat<<EOL > "/etc/systemd/system/x11vnc.service"
[Unit]
Description=Start x11vnc at startup
After=multi-user.target
Requires=graphical.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbport 5900 -shared -display :0
User=rpdv

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable x11vnc.service
sudo systemctl start x11vnc.service

echo "✅ x11vnc instalado sem senha e serviço iniciado!"

echo "Instalando o SSH..."

sudo apt-get update
sudo apt-get install -y openssh-server

echo "SSH instalado com sucesso."


#detectar tipo nitgen
        echo "Instalando a biometria..."
        
        # Atualiza os pacotes e instala a biometria
        sudo apt install -y build-essential linux-headers-$(uname -r)
	    git clone https://github.com/FingerTechBR/venus-linux-driver 
		chmod -R 777 *
		cd venus-linux-driver
		sudo make
		sudo ./install-driver.sh 
        echo "A biometria instalada com sucesso."

echo "Configurando autologin/autostart"
        usuario=$(logname)
        caminho="/home/$usuario"
        autostart_dir="$caminho/.config/autostart"
        mkdir "/etc/sddm.conf.d"
        mkdir -p "$autostart_dir"
        
        # iniciarsudo.desktop
        cat <<EOL > "$autostart_dir/iniciarsudo.desktop"
[Desktop Entry]
Exec=$caminho/./iniciarsudo.sh
Name=frente
Type=Application
Version=1.0
EOL


        cat <<EOL > "/etc/sddm.conf.d/autologin.conf"
[Autologin]
User=$usuario
Session=$DESKTOP_SESSION
EOL


echo "Autologin e autostart configurado!"
echo "Removendo protetor de tela do autostart!"
sudo rm /etc/xdg/autostart/lxqt-xscreensaver-autostart.destkop
echo "Xscreensaver removido!"

echo "⏰ Configurando fuso horário para America/Campo_Grande (GMT-4)..."
timedatectl set-timezone America/Campo_Grande

echo "🚫 Desativando proteção de tela e bloqueio..."

sudo -u rpdv bash -c "
  qdbus org.freedesktop.ScreenSaver /ScreenSaver SetActive false || true
  mkdir -p ~/.config/lxqt/
  sed -i '/^lockScreenOnSleep=/d' ~/.config/lxqt/session.conf 2>/dev/null || true
  echo 'lockScreenOnSleep=false' >> ~/.config/lxqt/session.conf
  sed -i '/^screensaverTimeout=/d' ~/.config/lxqt/session.conf 2>/dev/null || true
  echo 'screensaverTimeout=0' >> ~/.config/lxqt/session.conf
  sed -i '/^idleTime=/d' ~/.config/lxqt/session.conf 2>/dev/null || true
  echo 'idleTime=0' >> ~/.config/lxqt/session.conf
"
