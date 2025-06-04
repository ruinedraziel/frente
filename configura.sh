#!/bin/bash

clear
bold()          { ansi 1 "$@"; }
italic()        { ansi 3 "$@"; }
underline()     { ansi 4 "$@"; }
strikethrough() { ansi 9 "$@"; }
red()           { ansi 31 "$@"; }
green()         { ansi 32 "$@"; }
ansi()          { echo -e "\e[${1}m${*:2}\e[0m"; }


if [ "$(id -u)" != "0" ]; then
   echo 
   echo "["$(red ERROR)"]  Acesso negado... Rode este script como root"
   echo 
   exit 1
fi

teamviewer() {
   wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb 
   sudo apt install ./teamviewer_amd64.deb
   echo "TeamViewer instalado"
}

anydesk(){
    wget http://download.anydesk.com/linux/anydesk_6.3.2-1_amd64.deb -o anydesk.deb
    sudo dpkg -i anydesk.deb
    sudo apt-get install -f
   echo "AnyDesk instalado"
}

putty() {
    sudo apt-get install putty
	sudo usermod -a -G dialout rpdv
    sudo apt-get install screen
    echo "Putty instalado"
}

autostart() {
        usuario=$(logname)
        caminho="/home/$usuario"
        autostart_dir="$caminho/.config/autostart"
        mkdir -p "$autostart_dir"
        # fixaporta.desktop
        cat <<EOL > "$autostart_dir/fixaporta.desktop"
[Desktop Entry]
Exec=$caminho/./fixaporta.sh
Name=frente
Type=Application
Version=1.0
EOL

        # iniciarsudo.desktop
        cat <<EOL > "$autostart_dir/iniciarsudo.desktop"
[Desktop Entry]
Exec=$caminho/./iniciarsudo.sh
Name=frente
Type=Application
Version=1.0
EOL
echo "Arquivos de autostart criados para fixaporta.sh e iniciarsudo.sh!"
}

numlockx() {
            sudo apt update
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
            chown "$UsuarioReal:$UsuarioReal" "$DesktopFile"
            echo "Numlockx instalado."
}

vnc() {
        echo "Instalando x11vnc..."

        sudo apt update
        sudo apt install -y x11vnc expect

        UsuarioVNC=$(logname)
        senha_vnc="1"

        # Cria diretório de senha
        sudo -u "$UsuarioVNC" mkdir -p "/home/$UsuarioVNC/.vnc"

        # Usa expect para armazenar a senha do VNC
        expect <<EOF
spawn sudo -u $UsuarioVNC x11vnc -storepasswd
expect "Enter VNC password:"
send "$senha_vnc\r"
expect "Verify password:"
send "$senha_vnc\r"
expect "Write password to /home/$UsuarioVNC/.vnc/passwd?*"
send "y\r"
expect eof
EOF

        # Ajusta permissões
        sudo chmod 600 "/home/$UsuarioVNC/.vnc/passwd"
        sudo chown "$UsuarioVNC:$UsuarioVNC" "/home/$UsuarioVNC/.vnc/passwd"

        # Cria serviço systemd
        sudo tee /etc/systemd/system/x11vnc.service > /dev/null <<EOF
[Unit]
Description=Start x11vnc at startup
After=graphical.target
Requires=graphical.target

[Service]
Type=simple
ExecStartPre=/bin/sleep 10
ExecStart=/usr/bin/x11vnc -forever -usepw -display :0 -auth guess
User=$UsuarioVNC
Environment=DISPLAY=:0
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload
        sudo systemctl enable x11vnc.service
        sudo systemctl start x11vnc.service

        echo "✅ x11vnc instalado com senha '$senha_vnc' e serviço iniciado!"
    else
        echo "Instalação do VNC ignorada."
    fi
}

atalhos() {
INICIAR_SUDO_FILE="[Desktop Entry]
Type=Application
Name=Iniciar Sudo
Exec=/home/rpdv/iniciarsudo.senha
Icon=utilities-terminal
Terminal=true"
SISTEMA_INI_FILE="[Desktop Entry]
Type=Link
Name=Sistema.ini
URL=file:///home/rpdv/frente/sistema.ini
Icon=text-x-generic"
CONFIG_FILE="[Desktop Entry]
Version=1.0
Type=Link
Name=Config CFG
URL=file:///home/rpdv/frente/config.cfg
Icon=text-x-generic" 
DESKTOP_PATH="/home/rpdv/Desktop"
echo "$INICIAR_SUDO_FILE" > "$DESKTOP_PATH/IniciarSudo.desktop"
echo "$SISTEMA_INI_FILE" > "$DESKTOP_PATH/SistemaINI.desktop"
echo "$CONFIG_FILE" > "$DESKTOP_PATH/ConfigCFG.desktop"
chmod +x "$DESKTOP_PATH/IniciarSudo.desktop"
chmod +x "$DESKTOP_PATH/SistemaINI.desktop"
chmod +x "$DESKTOP_PATH/ConfigCFG.desktop"
DESKTOP_PATH="/home/rpdv/Área de trabalho"
echo "$INICIAR_SUDO_FILE" > "$DESKTOP_PATH/IniciarSudo.desktop"
echo "$SISTEMA_INI_FILE" > "$DESKTOP_PATH/SistemaINI.desktop"
echo "$CONFIG_FILE" > "$DESKTOP_PATH/ConfigCFG.desktop"
chmod +x "$DESKTOP_PATH/IniciarSudo.desktop"
chmod +x "$DESKTOP_PATH/SistemaINI.desktop"
chmod +x "$DESKTOP_PATH/ConfigCFG.desktop"

echo "Atalhos criados com sucesso na área de trabalho."
}

ssh() {
        echo "Instalando o SSH..."
        
        sudo apt-get update
        sudo apt-get install -y openssh-server

        echo "SSH instalado com sucesso."
}

nitgen() {
        echo "Instalando a biometria..."
        
        # Atualiza os pacotes e instala a biometria
        sudo apt install build-essential linux-headers-$(uname -r)
	    git clone https://github.com/FingerTechBR/venus-linux-driver 
		chmod -R 777 *
		cd venus-linux-driver
		sudo make
		sudo ./install-driver.sh 
        echo "A biometria instalada com sucesso."
}

sudo apt install net-tools

dependencias() {
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
        "libgtk2.0-0:i386"
        "libgtkmm-2.4-1c2:i386"
        "libcrypt1:i386"
        "libxml2:i386"
        "gtk2-engines:i386"
        "libcanberra-gtk-module:i386"
        "sqlite3:i386"
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
}

pdv(){
    cd /home/
    ./instalar.sh
}

PS3='Menu de instalação guiada: '
options=("TeamViewer" "AnyDesk" "Putty" "Dependências" "Ssh" "Vnc" "Automático" "Atalhos" "Numlockx" "Nitgen" "PDV" "Sair")
select opt in "${options[@]}"
do
    case $opt in
        "TeamViewer")
            teamviewer
            ;;
        "AnyDesk")
            anydesk
            ;;
        "Putty")
            ;;
        "Dependências")
            dependencias
            ;;
        "Ssh")
            ssh
            ;;
        "Vnc")
            vnc
            ;;
        "Automático")
            autostart           
           ;;
        "Atalhos")
            atalhos
            ;;
        "Numlockx")
            numlockx
            ;;
        "Nitgen")
            nitgen
            ;;
        "PDV")
            pdv
            ;;
        "Sair")
            break
            ;;
        *) echo "opcão invalida $REPLY";;
    esac
done

#feito por: Jefeson Miranda Operações, atualzado dia 22/05/25.
# menu online criador por: Rafael Mercado - 04/06/2025
