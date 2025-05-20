#!/bin/bash
echo "Instalando bibliotecas necessárias"
sudo apt install build-essential linux-headers-$(uname -r)
echo "Compilando"
cd ~/Downloads
git clone https://github.com/FingerTechBr/venus-linux-driver 
cd venus-linux-driver
chmod 777 *
sudo make
echo "Instalando driver nitgen"
sudo ./instala-driver.sh

