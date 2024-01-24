#### [SECTION] SSH LOCKDOWN for Remote Host ####

#### Backup the original sshd_config file
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

USERNAME=$(logname)


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

#### You may need to adjust these settings based on your requirements
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
    check_and_modify_option "Port" "4022"
    # Stops remote applications running via SSH connections
    check_and_modify_option "X11Forwarding" "no"
}

### Restart SSH service to apply changes
systemctl restart sshd

echo "SSH configuration has been updated and the service restarted."