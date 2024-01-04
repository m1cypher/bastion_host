#!/bin/bash

#### PAM Installation (REQUIRES SMART PHONE) Thank you Digital Ocean for the Walk Through
#### https://www.digitalocean.com/community/tutorials/how-to-set-up-multi-factor-authentication-for-ssh-on-ubuntu-20-04
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


#### [SECTION] PAM Configurations ####


##### Adds requires authentication items to SSH
sudo -S cp /etc/pam.d/sshd /etc/pam.d/sshd.bak
sudo echo "auth required pam_google_authenticator.so" >> /etc/pam.d/sshd 
sudo echo "auth required pam_permit.so" >> /etc/pam.d/sshd

##### Changes SSH acceptance methods to be PublicKey, MFA
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes' /etc/ssh/sshd_config
sudo echo "AuthenticationMethods publickey,password publickey,keyboard-interactive" >> /etc/ssh/sshd_config
#### Stops password only logins
sudo sed -i 's/^@include common-auth/#&/' /etc/pam.d/sshd

service ssh restart

echo "PAM configuration has been updated and the service restarted."



#### [SECTION] SSH LOCKDOWN for Bastion Host ####

# Prompt the user for the mode: automatic or interactive
read -p "Do you want to make the changes automatically? (yes/no): " mode

# Backup the original sshd_config file
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Function to confirm changes
function confirm_change {
    read -p "Do you want to apply this change? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Change skipped."
        exit 1
    fi
}

# Function to apply changes interactively
function apply_interactively {
    echo "Please enter the new value for each setting (options/suggestions in parenthases) or leave blank to skip."

    # Modify PermitRootLogin
    read -p "PermitRootLogin (yes/no): " new_value
    if [ -n "$new_value" ]; then
        sudo sed -i "s/^PermitRootLogin.*/PermitRootLogin $new_value/" /etc/ssh/sshd_config
        confirm_change
    fi

    # Modify Protocol
    read -p "Protocol (2): " new_value
    if [ -n "$new_value" ]; then
        sudo sed -i "s/^Protocol.*/Protocol $new_value/" /etc/ssh/sshd_config
        confirm_change
    fi

        # Modify MaxAuthTries
    read -p "MaxAuthTries (3): " new_value
    if [ -n "$new_value" ]; then
        sudo sed -i "s/^MaxAuthTries.*/MaxAuthTries $new_value/" /etc/ssh/sshd_config
        confirm_change
    fi

    # Modify ClientAliveInterval
    read -p "ClientAliveInterval (300): " new_value
    if [ -n "$new_value" ]; then
        sudo sed -i "s/^ClientAliveInterval.*/ClientAliveInterval $new_value/" /etc/ssh/sshd_config
        confirm_change
    fi

    # Modify ClientAliveCountMax
    echo "Sets the number of concurrent logins"
    read -p "ClientAliveCountMax (2): " new_value
    if [ -n "$new_value" ]; then
        sudo sed -i "s/^ClientAliveCountMax.*/ClientAliveCountMax $new_value/" /etc/ssh/sshd_config
        confirm_change
    fi

    # Modify PermitEmptyPasswords
    echo "Without setting this, logins can attempt to login without a password"
    read -p "PermitEmptyPasswords (no): " new_value
    if [ -n "$new_value" ]; then
        sudo sed -i "s/^PermitEmptyPasswords.*/PermitEmptyPasswords $new_value/" /etc/ssh/sshd_config
        confirm_change
    fi

    # Modify PubkeyAuthentication
    echo "Requires publickey would recommend this, but we achieve a different result with PAM."
    read -p "PubkeyAuthentication (yes): " new_value
    if [ -n "$new_value" ]; then
        sudo sed -i "s/^PubkeyAuthentication.*/PubkeyAuthentication $new_value/" /etc/ssh/sshd_config
        confirm_change
    fi

    # Modify PasswordAuthentication
    echo "Sets password authentication, but we achieve a different result with PAM 'AuthenticationMethods'."
    read -p "PasswordAuthentication (no): " new_value
    if [ -n "$new_value" ]; then
        sudo sed -i "s/^PasswordAuthentication.*/PasswordAuthentication $new_value/" /etc/ssh/sshd_config
        confirm_change
    fi

    # Modify AllowUsers
    echo "Restricts SSH to ONLY listed user, specifically the one user created above."
    read -p "AllowUsers (username): " new_value
    if [ -n "$new_value" ]; then
        sudo sed -i "s/^AllowUsers.*/AllowUsers $USERNAME/" /etc/ssh/sshd_config
        confirm_change
    fi

    # Modify AllowGroups
    read -p "Script does not currently create a special Group, but you can set one if you want. AllowGroups (groupname) : " new_value
    if [ -n "$new_value" ]; then
        sudo sed -i "s/^AllowGroups.*/AllowGroups $new_value/" /etc/ssh/sshd_config
        confirm_change
    fi

    # Modify Port
    echo "Changes the SSH Port. Generally, I am against this as it really doesn't serve a purpose sense a targeted scan would still be able to find OpenSSH." 
    echo "However, automated bots do just hammer port 22 so changing it to something different isn't a bad idea."
    read -p "Port (2222): " new_value
    if [ -n "$new_value" ]; then
        sudo sed -i "s/^Port.*/Port $new_value/" /etc/ssh/sshd_config
        confirm_change
    fi

    # Modify X11Forwarding
    echo "Stops remote applications running via SSH connections"
    read -p "X11Forwarding (no): " new_value
    if [ -n "$new_value" ]; then
        sudo sed -i "s/^X11Forwarding.*/X11Forwarding $new_value/" /etc/ssh/sshd_config
        confirm_change
    fi

    # Restart SSH service to apply changes
    service ssh restart

    echo "SSH configuration has been updated and the service restarted."
    exit 0
}

# Function to apply changes automatically
function apply_automatically {
    # Edit sshd_config with desired settings using sed
    # You may need to adjust these settings based on your requirements
    sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    # Sets to Protocol 2 rather than 1 which has known vulnerabilities.
    sudo sed -i 's/^Protocol.*/Protocol 2/' /etc/ssh/sshd_config
    # Sets the number of retries if the user fails to authenticate within the allowed number of attempts, the connection will be terminated.
    sudo sed -i 's/^MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
    # Sets the length of a connection without action
    sudo sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
    # Sets the number of concurrent logins
    sudo sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 2/' /etc/ssh/sshd_config
    sudo sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
    # Requires publickey would recommend this, but we achieve a different result with PAM.
    sudo sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    # Sets password authentication, but we achieve a different result with PAM "AuthenticationMethods".
    sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i "s/^AllowUsers.*/AllowUsers $USERNAME/" /etc/ssh/sshd_config
    # Use this if you want to create a group that is allowed rather than the individual user like above
    # sed -i 's/^AllowGroups.*/AllowGroups groupname/' /etc/ssh/sshd_config
    # Changes the SSH Port. Generally, I am against this as it really doesn't serve a purpose sense a targeted scan would still be able to find OpenSSH.
    # However, automated bots do just hammer port 22 so changing it to something different isn't a bad idea.
    sudo sed -i 's/^Port.*/Port 30022/' /etc/ssh/sshd_config  # Change the port to a non-standard value
    # Stops remote applications running via SSH connections
    sudo sed -i 's/^X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config


    # Restart SSH service to apply changes
    service ssh restart

    echo "SSH configuration has been updated and the service restarted."
    exit 0
}

# Check the user's choice and proceed accordingly
if [ "$mode" == "yes" ]; then
    apply_automatically
elif [ "$mode" == "no" ]; then
    apply_interactively
else
    echo "Invalid choice. Exiting."
    exit 1
fi



#### [SECTION] SSH PubKey Copy ####

read -p "Is the menu ready? (yes/no): " menu_ready

if [[ $menu_ready != "yes" ]]; then
    echo "Menu is not ready. Exiting."
    exit 1
fi

MENU_FILE="./sshhost_menu.txt"

PUBLIC_KEY_FILE="~/.ssh/bastion_key.pub"

declare -A menu_options
while IFS=':' read -r key label command; do
    menu_options["$key"]="$label:$command"
done < "$MENU_FILE"

for key in "${!menu_options[@]}"; do
    # Extract host from ssh command
    host_ssh_command=${menu_options[$key]#*:}
    host=${host_ssh_command##*@}

    # Add public key to authorized_keys for the host
    ssh-copy-id -i "$PUBLIC_KEY_FILE" "$host"
done


#### [SECTION] New User SSH Menu ####
cat ./ssh_menu.txt >> .bashrc
