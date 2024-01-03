# Changelog


## v0.6.0

### Added or Changed
# ssh_lockdown_local.sh
- Created new file
- Added the following sections from 'new_user.sh': PAM, SSH Keygen, SSH Copy, SSH Menu, SSH Config

### Removed
# new_user.sh
- Removed the following sections PAM, SSH Keygen, SSH Copy, SSH Menu, SSH Config

## v0.5.1

### Changed
- Corrected user switch and rest of thes script execution. #Original option did work due to multiple " ' " marks


## v0.5.0

### Added or Changed
# new_user.sh
- Added fully automated SSH changes or an interactive mode
- Interactive mode does have an explanation for each change
- Added question if the Menu (sshhost_menu.txt) is ready. If not script exit's to not waste time sending ssh keys to no host.

# ssh_menu.txt
- Added bash history time formatting

### Removed
- Previous SSH config changes to have automatic or interactive mode.

## v0.0.0

### Added or Changed
- Added changelog
- Fixed typos in scripts
- Added inital features

### Removed

- 
