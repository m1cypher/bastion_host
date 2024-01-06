#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or using sudo."
    exit 1
fi

######### UBUNTU VERSION SPECIFC ITEM TEST #######

UBUNTU_VERSION=$(lsb_release -sr)


function check_and_modify_option {
  OPTION="$1"
  VALUE="$2"
  grep -i "^$OPTION" /etc/ssh/sshd_config > /dev/null
  if [ $? -eq 0 ]; then
    sed -i "s/^$OPTION .*/$OPTION $VALUE/" /etc/ssh/sshd_config
  else
    echo "$OPTION $VALUE" >> /etc/ssh/sshd_config
  fi
}

#### [MAJOR SECTION] Ubuntu 20.04 configuration function ####
### Thank you Digital Ocean for the Walk Through ###
### https://www.digitalocean.com/community/tutorials/how-to-set-up-multi-factor-authentication-for-ssh-on-ubuntu-20-04 ###
function configure_pam_20_04 {
    echo "Configuring for Ubuntu version $UBUNTU_VERSION"
    #### [SECTION] PAM Configurations 20.04 ####
    # Backing up pam.d/sshd file
    cp /etc/pam.d/sshd /etc/pam.d/sshd.bak
    # nullok at the end of the first line, make sure the users who yet haven’t registered for 2FA can use the sudo as they were doing. 
    # If you remove this line, all users need to enter a 2FA code to access sudo.
    echo "auth required pam_google_authenticator.so" nullok >> /etc/pam.d/common-auth
    echo "auth required pam_permit.so" >> /etc/pam.d/common-auth
    echo "auth required pam_permit.so" >> /etc/pam.d/sshd

    #### [SECTION] PAM Configurations for SSH on 20.04 ####
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak1
    check_and_modify_option "ChallengeResponseAuthentication" "yes"
    check_and_modify_option "AuthenticationMethods" "publickey,keyboard-interactive"

    #### [SECTION] Service Restart ####
    systemctl restart sshd
    echo "PAM configuration has been updated and the ssh service restarted."
    sleep 3
}


#### [MAJOR SECTION] Ubuntu 22.04 configuration function ####
### Help from https://linux.how2shout.com/how-to-use-google-two-factor-authentication-with-ubuntu-22-04/ ###
function configure_pam_22_04 {
    echo "Configuring for Ubuntu version $UBUNTU_VERSION"
    #### [SECTION] PAM Configurations 22.04 ####
    # Backing up pam.d/sshd file
    cp /etc/pam.d/sshd /etc/pam.d/sshd.bak
    # nullok at the end of the first line, make sure the users who yet haven’t registered for 2FA can use the sudo as they were doing. 
    # If you remove this line, all users need to enter a 2FA code to access sudo.
    sed -i '/^\@include common-auth$/ {
        n
        a auth required pam_google_authenticator.so
    }' /etc/pam.d/sshd

    #### [SECTION] PAM Configurations for SSH on 22.04 ####
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak1
    check_and_modify_option "KbdInteractiveAuthentication" "yes"

    #### [SECTION] Service Restart ####
    systemctl restart sshd
    echo "PAM configuration has been updated and the ssh service restarted."
    sleep 3
    }

if [[ $UBUNTU_VERSION == "20.04" ]]; then
  configure_pam_20_04
elif [[ $UBUNTU_VERSION == '22.04' ]]; then
  configure_pam_22_04
else
  echo "Ubuntu version not supported."
  exit 1
fi

#### [SECTION] SSH LOCKDOWN for Bastion Host ####

echo "We need to gather some information for the next section of locking down your bastion ssh server"
# Prompt the user for the mode: automatic or interactive
read -p "Do you want to make the changes automatically? (yes/no): " mode
# Asking for SSH port information
read -p "What port do you want to change the SSH server to? (4022): " port
# Gathering current user to set variable $USERNAME
read -p "Setting variable 'USERNAME'. What username do you want to have access to ssh? You are logged in as $(logname): " USERNAME



# Backup the original sshd_config file
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak2

# Function to apply changes interactively
function apply_interactively {
    echo "Please enter the new value for each setting (options/suggestions in parenthases) or leave blank to skip."

    # Modify PermitRootLogin
    read -p "PermitRootLogin (no): " new_value
    if [ -n "$new_value" ]; then
        check_and_modify_option "PermitRootLogin" $new_value
    fi

    # Modify MaxAuthTries
    read -p "MaxAuthTries (3): " new_value
    if [ -n "$new_value" ]; then
        check_and_modify_option "MaxAuthTries" $new_value
    fi

    # Modify ClientAliveInterval
    read -p "ClientAliveInterval (300): " new_value
    if [ -n "$new_value" ]; then
        check_and_modify_option "ClientAliveInterval" $new_value
    fi

    # Modify ClientAliveCountMax
    echo "Sets the number of concurrent logins"
    read -p "ClientAliveCountMax (2): " new_value
    if [ -n "$new_value" ]; then
        check_and_modify_option "ClientAliveCountMax" $new_value
    fi

    # Modify PermitEmptyPasswords
    echo "Without setting this, logins can attempt to login without a password"
    read -p "PermitEmptyPasswords (no): " new_value
    if [ -n "$new_value" ]; then
        check_and_modify_option "PermitEmptyPasswords" $new_value 
    fi

    # Modify PubkeyAuthentication
    echo "Requires publickey would recommend this, but we achieve a different result with PAM."
    read -p "PubkeyAuthentication (yes): " new_value
    if [ -n "$new_value" ]; then
        check_and_modify_option "PubkeyAuthentication" $new_value  
    fi

    # Modify PasswordAuthentication
    echo "Sets password authentication, but the minimum requirement is overridden by the PAM configuration."
    read -p "PasswordAuthentication (no): " new_value
    if [ -n "$new_value" ]; then
        check_and_modify_option "PasswordAuthentication" $new_value 
    fi

    # Modify AllowUsers
    echo "Restricts SSH to ONLY listed user, specifically the one user created previously."
    read -p "AllowUsers ($USERNAME): " new_value
    if [ -n "$new_value" ]; then
        check_and_modify_option "AllowUsers" $USERNAME 
    fi

    # Modify AllowGroups
    read -p "Script does not currently create a special Group, but you can set one if you want. If you press enter it will just skip. AllowGroups (groupname) : " new_value
    if [ -n "$new_value" ]; then
        check_and_modify_option "AllowGroups" $new_value
    fi

    # Modify Port
    echo "Changes the SSH Port. Generally, I am against this as it really doesn't serve a purpose sense a targeted scan would still be able to find OpenSSH." 
    echo "However, automated bots do just hammer port 22 so changing it to something different isn't a bad idea."
    echo "We already set this number, but you can change it here"
    read -p "Port (4022): " new_value
    if [ -n "$new_value" ]; then
        check_and_modify_option "Port" $new_value
    else
        check_and_modify_option "Port" $port
    fi

    # Modify X11Forwarding
    echo "Stops remote applications running via SSH connections"
    read -p "X11Forwarding (no): " new_value
    if [ -n "$new_value" ]; then
        check_and_modify_option "X11Forwarding" $new_value
    fi

    # Turn off Port Forwarding
    echo "Stops port forwading"
    read -p "AllowTcpForwading (no): " new_value
    if [ -n "$new_value" ]; then
        check_and_modify_option "AllowTcpForwarding" $new_value
    fi

    # Restart SSH service to apply changes
    systemctl restart sshd

    echo "SSH configuration has been updated and the service restarted."
    exit 0
}

# Function to apply changes automatically
function apply_automatically {
    # Edit sshd_config with desired settings using sed
    # You may need to adjust these settings based on your requirements
    check_and_modify_option "PermitRootLogin" "no"
    # Sets the number of retries if the user fails to authenticate within the allowed number of attempts, the connection will be terminated.
    check_and_modify_option "MaxAuthTries" "3"
    # Sets the length of a connection without action
    check_and_modify_option "ClientAliveInterval" "300"
    # Sets the number of concurrent logins
    check_and_modify_option "ClientAliveCountMax" "2"
    # Sets no empty passwords
    check_and_modify_option "PermitEmptyPasswords" "no"
    # Requires publickey would recommend this, but we achieve a different result with PAM.
    check_and_modify_option "PubkeyAuthentication" "yes"
    # Sets password authentication, but we achieve a different result with PAM "AuthenticationMethods".
    check_and_modify_option "PasswordAuthentication" "no"
    # Allow a specific user to access SSH
    check_and_modify_option "AllowUsers" $USERNAME
    # Use this if you want to create a group that is allowed rather/with than the individual user like above. Commenting out since it is not set by the script.
    # check_and_modify_option AllowGroups $groupname
    # Changes the SSH Port. Generally, I am against this as it really doesn't serve a purpose sense a targeted scan would still be able to find OpenSSH.
    # However, automated bots do just hammer port 22 so changing it to something different isn't a bad idea.
    check_and_modify_option "Port" $port
    # Stops remote applications running via SSH connections
    check_and_modify_option "X11Forwarding" "no"


    # Restart SSH service to apply changes
    systemctl restart sshd
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

