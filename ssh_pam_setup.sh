#!/bin/bash

#### PAM Installation (REQUIRES SMART PHONE)
#### [SECTION] Installs Google PAM ####
sudo apt-get update
sudo apt-get install libpam-google-authenticator -y

##### Runs Google PAM setup with TOTP (-t), disallowed reuses of TOTP (-d), rate limited logins for 3 every 30 seconds (-r 3, -R 30), and disable the questions being asked (-W)
google-authenticator -t -d -r 3 -R 30 -W 

#### YOU WILL HAVE TO SAY "Y" to the last section to ensure you copy commands to profile. This also forces you to scan the QR code to your authenticator ####
#### SAVE EMERGENCY CODES ###

echo "Did you save your ememergency codes?" 

sleep 5



#### [SECTION] publickey creation ####
ssh-keygen -t rsa -b 2048 -f ~/.ssh/bastion_key

#### [SECTION] Execution of ssh_lockdown_local ####

sudo -S ./ssh_lockdown_local.sh


#### [SECTION] SSH PubKey Copy ####

read -p "Is the menu ready? (yes/no): " menu_ready

if [[ $menu_ready != "yes" ]]; then
    echo "Menu is not ready. Exiting."
    exit 1
fi

MENU_FILE="./sshhost_menu.txt"

PUBLIC_KEY_FILE="/home/$USER/.ssh/bastion_key.pub"

while IFS=':' read -r key label command; do
    # Skipping commented lines
    [[ $key =~ ^[[:space:]]*# ]] && continue
    # Skip empty lines
    [[ -z $key || -z $label || -z $command ]] && continue


    menu_options["$key"]="$label:$command"
done < "$MENU_FILE"

for key in "${!menu_options[@]}"; do
    [[ $key =~ ^[[:space:]]*# ]] && continue

    # Extract host from ssh command
    host_ssh_command=${menu_options[$key]#*:}
    IFS=' ' read -ra host_ssh_command_array <<< "$host_ssh_command"
    host=${host_ssh_command##*@}

    # Debugging: Print information for each iteration
    echo "Processing key: $key, Host: $host, Command: ${menu_options[$key]}"

    # Add public key to authorized_keys for the host
    ssh-copy-id -i "$PUBLIC_KEY_FILE" "$host"
done

#### [SECTION] Remote Host SSH Lockdown
for key in "${!menu_options[@]}"; do
    # Extract host from ssh command
    host_ssh_command=${menu_options[$key]#*:}
    host=${host_ssh_command##*@}

    # Add public key to authorized_keys for the host
    $host 'bash -s' < ssh_lockdown_remote.sh
done


#### [SECTION] New User SSH Menu ####
cat ./ssh_menu.txt >> .bashrc
