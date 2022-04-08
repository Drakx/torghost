# package_management()
# Finds if the current package management system is deb, rpm or pacman based
function package_management() {
    if (command -v yum || command -v zypper) >/dev/null; then
        local type="rpm"
    elif command -v deb >/dev/null; then
        local type="deb"
    elif command -v pacman >/dev/null; then
        local type="pacman"
    fi
    echo $type
}

res=$(package_management)

echo "Torghost installer v3.0"
echo "Installing prerequisites "
if [[ $res == "rpm" ]]; then
    sudo yum install tor python39-pip -y
elif [[ $res == "deb" ]]; then
    sudo apt-get install tor python3-pip -y 
elif [[ $res == "pacman" ]]; then
    sudo pacman -S tor python-pip -y
fi
echo "Installing dependencies "
sudo pip3 install -r requirements.txt 
mkdir build
cd build

if [ -f "/usr/bin/cython3" ]; then 
	cython3 ../torghost.py --embed -o torghost.c --verbose
elif [ -f "/usr/bin/cython" ]; then
	# OpenSuSE 
	cython ../torghost.py --embed -o torghost.c --verbose
fi

if [ $? -eq 0 ]; then
    echo [SUCCESS] Generated C code
else
    echo [ERROR] Build failed. Unable to generate C code using cython3
    exit 1
fi
gcc -Os -I /usr/include/python3.8 -o torghost torghost.c -lpython3.8 -lpthread -lm -lutil -ldl
if [ $? -eq 0 ]; then
    echo [SUCCESS] Compiled to static binay 
else
    echo [ERROR] Build failed
    exit 1
fi
sudo cp -r torghost /usr/bin/
if [ $? -eq 0 ]; then
    echo [SUCCESS] Copied binary to /usr/bin 
else
    echo [ERROR] Unable to copy
    exit 1
fi

