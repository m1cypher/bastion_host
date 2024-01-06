#### [SECTION] SSH LOCKDOWN for Remote Host ####

#### Backup the original sshd_config file
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

#### You may need to adjust these settings based on your requirements
### Ensure the "ROOT" cannot SSH in
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
### Change to SSH Protocol 2
sed -i 's/^Protocol.*/Protocol 2/' /etc/ssh/sshd_config
### Limits SSH Attempts
sed -i 's/^MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
### Limits SSH timeout 
sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 2/' /etc/ssh/sshd_config
### Stops empty password attempts
sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
### Requires publickey would recommend this, but we achieve a different result with PAM.
# sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
### Sets password authentication, but we achieve a different result with PAM "AuthenticationMethods".
# sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
### Restricts SSH to ONLY one user, the user created above
sed -i "s/^AllowUsers.*/AllowUsers $USERNAME/" /etc/ssh/sshd_config
### Use this if you want to create a group that is allowed rather than the individual user like above.
# sed -i 's/^AllowGroups.*/AllowGroups groupname/' /etc/ssh/sshd_config
### Changes the SSH Port. Generally, I am against this as it really doesn't serve a purpose sense a targeted scan would still be able to find OpenSSH.
### However, automated bots do just hammer port 22 so changing it to something different isn't a bad idea.
# sed -i 's/^Port.*/Port 30022/' /etc/ssh/sshd_config  # Change the port to a non-standard value
### Stops remote applications running via SSH connections
sed -i 's/^X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config

### Restart SSH service to apply changes
systemctl restart sshd

echo "SSH configuration has been updated and the service restarted."