#!/bin/bash
xline="----------------------------"
PS3=$'\nPlease enter: '

function mariaDb_menu { 
    init_title "MariaDb"
    select opt in Install Remove Menu;
    do
        echo -e "$opt...\n"
        case "$opt" in
            "Install")
                USERDB="ivm_admin"
                MAINDB="ivm_data"
                PASSWDDB="12345678"

                sudo apt update
                sudo apt install mariadb-server -y
                sudo systemctl status mariadb
                sudo mysql_secure_installation
                
                sudo mariadb -e "CREATE DATABASE IF NOT EXISTS ${MAINDB} CHARACTER SET utf8 COLLATE utf8_general_ci;"
                sudo mariadb -e "DROP USER IF EXISTS ${USERDB};"
                sudo mariadb -e "CREATE USER '${USERDB}'@'%' IDENTIFIED BY '${PASSWDDB}';"
                sudo mariadb -e "GRANT ALL PRIVILEGES ON *.* TO '${USERDB}'@'%' WITH GRANT OPTION;"

                #sudo mariadb -e "CREATE USER ${USERDB}@localhost IDENTIFIED BY '${PASSWDDB}';"
                #sudo mariadb -e "GRANT ALL PRIVILEGES ON ${MAINDB}.* TO '${USERDB}'@'localhost';"
                
                sudo mariadb -e "FLUSH PRIVILEGES;"
                sudo mariadb -e "SELECT user FROM mysql.user;"
                sudo mariadb -e "SHOW DATABASES;"
            ;;
            "Remove")
                sudo apt-get purge mariadb-server
            ;;
            "Menu")
                main_menu
                break
            ;;
        esac
        init_title "MariaDb"
        REPLY=
    done
}
function nodeJS_menu {   
    init_title "NodeJS"
    myVer="v18.20.5"
    select opt in Install Remove NPM_Install Menu;
    do
        echo "$opt"$'...\n'

        case "$opt" in
            "Install")
                sudo apt-get update
                sudo apt install curl
                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
                source ~/.nvm/nvm.sh
                nvm --version
                nvm install "$myVer"
                nvm use 18
            ;;
            "Remove")
                source ~/.nvm/nvm.sh
                nvm uninstall "$myVer"
                sudo rm -r ~/.nvm
            ;;
            "NPM_Install")
                testNode
                cd ~/ivm-app
                npm install
            ;;
            "Menu")
                main_menu
                break
            ;;
        esac
        init_title "NodeJS"
        REPLY=
    done
}

function nginx_menu {

nginx_cnf=$(cat <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    #listen 443 ssl;
    #listen [::]:443 ssl;
    
    index index.html index.htm;
    
    client_max_body_size 25M;
    #server_name example2.com www.example2.com 192.168.1.254;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;	
    }
}
EOF
)

    myPath=/etc/nginx/sites-available/ivm.cnf
    function nginx_cnf {
        sudo rm -f /etc/nginx/sites-enabled/default
        if [ ! -f $myPath ]; then
            echo "$nginx_cnf" | sudo tee "$myPath" > /dev/null
        fi
        sudo nano "$myPath"        
        sudo ln -sf "$myPath" /etc/nginx/sites-enabled/
        sudo nginx -t && sudo systemctl restart nginx        
    }

    init_title "Nginx"

    select opt in Install Remove Configure Menu;
    do
        echo "$opt"$'...\n'

        case "$opt" in
            "Install")
                sudo apt update
                sudo apt install nginx               
                nginx_cnf
                sudo ufw allow 'Nginx Full'
            ;;
            "Remove")
                sudo apt-get purge nginx nginx-common

                #remove dependencies by nginx which are no longer required
                #sudo apt-get autoremove
            ;;
            "Configure")
                nginx_cnf
            ;;
            "Menu")
                main_menu
                break
            ;;
        esac
        init_title "Nginx"
        REPLY=
    done
}
function pm2_menu {
    init_title "PM2"
    select opt in Install Remove StartupNode StartNode StopNode Menu;
        do
            echo "$opt"$'...\n'

            case "$opt" in
                "Install")
                    testNode
                    npm install pm2@latest -g
                ;;
                "Remove")
                    pm2 kill
                    npm remove pm2 -g
                ;;
                "StartupNode")
                    cd ~/ivm-app
                    pm2 start index.js
                    pm2 save
                    pm2 startup
                    nodeDir="$(dirname "$(which node)")"
                    pm2Dir="$(dirname "${nodeDir}")/lib/node_modules/pm2/bin/pm2"
                    sudo env PATH=$PATH:"$nodeDir" "$pm2Dir" startup systemd -u "$USER" --hp "$HOME"                    
                ;;
                "StartNode")
                    cd ~/ivm-app
                    pm2 start index.js
                ;;
                "StopNode")
                    pm2 stop index
                ;;
                "Menu")
                    main_menu
                    break
                ;;
            esac
            init_title "PM2"
            REPLY=
        done
}
function ssl_menu {
    init_title "SSL"
    select opt in Install Remove Menu;
        do
            echo "$opt"$'...\n'

            case "$opt" in
                "Install")
                    sudo apt-get update
                    sudo apt-get install certbot python3-certbot-nginx
                    sudo systemctl reload nginx
                    sudo certbot --nginx
                    sudo systemctl status certbot.timer
                    sudo certbot renew --dry-run
                ;;
                "Remove")
                    sudo certbot delete
                    sudo apt-get purge certbot python3-certbot-nginx
                    sudo apt autoremove
                    sudo systemctl reload nginx
                ;;
                "Menu")
                    main_menu
                    break
                ;;
            esac
            init_title "SSL"
            REPLY=
        done
}
function ssh_menu {
    init_title "SSH"
    select opt in Install Remove Enable Disable PubKey Configure Keygen Menu;
        do
            echo "$opt"$'...\n'

            case "$opt" in
                "Install")
                    sudo apt install openssh-server
                    sudo systemctl status ssh
                    sudo ufw allow ssh
                ;;
                "Remove")
                    sudo apt remove openssh-server
                ;;
                "Enable")
                    sudo systemctl enable -now ssh
                ;;
                "Disable")
                    sudo systemctl disable -now ssh
                ;;
                "PubKey")
                    sudo nano ~/.ssh/authorized_keys
                ;;
                "Configure")
                    sudo nano /etc/ssh/sshd_config
                ;;
                "Keygen")
                    ssh-keygen -t rsa
                ;;
                "Menu")
                    main_menu
                    break
                ;;
            esac
            init_title "SSH"
            REPLY=
        done
}
function init_title {
    echo $xline
    echo "${1:-Main Menu}"
    echo $xline
}
function testNode {
    if ! command -v node 2>&1 >/dev/null
    then
        source ~/.nvm/nvm.sh
        nvm on
    fi
}
function main_menu {
    #Create menu
    #Match multiple conditions ;;&
    clear
    init_title

    submenu=("MariaDb"
            "NodeJS"
            "Nginx"
            "PM2"
            "SSL"
            "SSH"
            "Exit")
    select sub in "${submenu[@]}";
    do
        #echo "$sub ..."
        case "$sub" in
            "MariaDb") mariaDb_menu ;;
            "NodeJS") nodeJS_menu ;;
            "Nginx") nginx_menu ;;
            "PM2") pm2_menu ;;
            "SSL") ssl_menu ;;
            "SSH") ssh_menu ;;
            "Exit") exit ;;
        esac
    done  
}

main_menu