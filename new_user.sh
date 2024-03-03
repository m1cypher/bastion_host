#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or using sudo."
    exit 1
fi


# Assign username and password from command line arguments
read -p 'What username do you want to login with and restrict SSH to? ' USERNAME

read -p 'What do you want the password to be? ' PASSWORD


###### [FEATURE] Allow for an option to skip the question with arguments rather than questions above ####
# Check if username and password are provided as arguments
# if [ "$#" -ne 2 ]; then
#     echo "Usage: $0 <username> <password>"
#     exit 1
# fi

# # Assign username and password from command line arguments
# USERNAME=$1
# PASSWORD=$2

# Set the password for the new user

#### [FEAUTRE] ####


#### [SECTION] Create a new user ####
useradd -m -s /bin/bash $USERNAME

echo "$USERNAME:$PASSWORD" | chpasswd

#### Print a message indicating success
echo "User '$USERNAME' created with the specified password. Adding user to Sudo group."

usermod -aG sudo $USERNAME

echo "Check to make sure that '$USERNAME' is part of the sudo group."

id odin

sleep 5

echo "Moving ssh_lockdown_local.sh and ssh_pam_setup.sh to /home/$USERNAME."

cp ./local_lockdown.sh /home/$USERNAME
cp ./remote_lockdown.sh /home/$USERNAME
cp ./pam_setup.sh /home/$USERNAME

echo "Changing permissions on ssh_lockdown_local.sh and ssh_pam_setup.sh."

chmod +x /home/$USERNAME/local_lockdown.sh
chmod +x /home/$USERNAME/remote_lockdown.sh
chmod +x /home/$USERNAME/pam_setup.sh

echo "Switching terminal to $USERNAME"

su - $USERNAME -c "/home/$USERNAME/ssh_pam_setup.sh"