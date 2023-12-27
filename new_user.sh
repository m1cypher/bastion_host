#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or using sudo."
    exit 1
fi

# Check if username and password are provided as arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <username> <password>"
    exit 1
fi

# Assign username and password from command line arguments
read -p 'What username do you want to login with and restrict SSH to? ' USERNAME

# Create a new user
adduser $USERNAME

# Print a message indicating success
echo "User '$USERNAME' created with the specified password."


# PAM Installation (REQUIRES SMART PHONE) Thank you Digital Ocean for the Walk Through
# https://www.digitalocean.com/community/tutorials/how-to-set-up-multi-factor-authentication-for-ssh-on-ubuntu-20-04
# Installs Google PAM
sudo apt-get update
sudo apt-get install libpam-google-authenticator -y

# Runs Google PAM setup with TOTP (-t), disallowed reuses of TOTP (-d), and rate limited logins for 3 every 30 seconds (-r 3, -R 30)
google-authenticator -t -d -r 3 -R 30

#### YOU WILL HAVE TO SAY "Y" to the last section to ensure you copy commands to profile. This also forces you to scan the QR code to your authenticator ####

# Adds requires authentication items to SSH
sudo cp /etc/pam.d/sshd /etc/pam.d/sshd.bak
echo "auth required pam_google_authenticator.so nullok" >> /etc/pam.d/sshd 
echo "auth required pam_permit.so" >> /etc/pam.d/sshd

# Changes SSH acceptance methods to be PublicKey, MFA
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes' /etc/ssh/sshd_config
echo "AuthenticationMethods password publickey,keyboard-interactive" >> /etc/ssh/sshd_config
# Stops password only logins
sed -i 's/^@include common-auth/#&/' /etc/pam.d/sshd

service ssh restart

echo "PAM configuration has been updated and the service restarted."



# SSH LOCKDOWN for current Host

# Backup the original sshd_config file
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# You may need to adjust these settings based on your requirements
# Ensure the "ROOT" cannot SSH in
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
# Change to SSH Protocol 2
sed -i 's/^Protocol.*/Protocol 2/' /etc/ssh/sshd_config
# Limits SSH Attempts
sed -i 's/^MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
# Limits SSH timeout 
sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 2/' /etc/ssh/sshd_config
# Stops empty password attempts
sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
# Requires publickey would recommend this, but we achieve a different result with PAM
# sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
# Sets password authentication that will be MFA enforced with PAM
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
# Restricts SSH to ONLY one user, the user created above
sed -i "s/^AllowUsers.*/AllowUsers $USERNAME/" /etc/ssh/sshd_config
# Use this if you want to create a group that is allowed
# sed -i 's/^AllowGroups.*/AllowGroups groupname/' /etc/ssh/sshd_config
# Changes the SSH Port. 
# sed -i 's/^Port.*/Port 2222/' /etc/ssh/sshd_config  # Change the port to a non-standard value
# Stops remote applications running via SSH connections
sed -i 's/^X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config

# Restart SSH service to apply changes
service ssh restart

echo "SSH configuration has been updated and the service restarted."
