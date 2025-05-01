#!/bin/bash
set -euo pipefail

while true; do
    read -rp "Enter a username you want to login as: " username
    if [[ "$username" =~ ^[a-z][-a-z0-9_]*$ ]]; then
        break
    else
        echo "⚠️  Invalid username. Use lowercase letters, digits, underscores; must start with a letter."
    fi
done

while true; do
    read -rsp "Enter a password for that user: " password1; echo
    read -rsp "Confirm password: " password2; echo
    if [[ "$password1" == "$password2" && -n "$password1" ]]; then
        break
    else
        echo "⚠️  Passwords do not match. Please try again."
    fi
done

if id "$username" &>/dev/null; then
    echo "❌ User $username already exists." >&2
    exit 1
fi

useradd --create-home --shell /bin/zsh "$username"
echo "${username}:${password1}" | chpasswd
usermod -aG sudo "$username"

mkdir /home/$username/.ssh
chmod 700 /home/$username/.ssh
sudo cp /root/.ssh/authorized_keys /home/$username/.ssh/authorized_keys
chmod 600 /home/$username/.ssh/authorized_keys
sudo chown -R $username:$username /home/$username/.ssh

SSHCFG='/etc/ssh/sshd_config'
50CLOUDINIT='/etc/ssh/sshd_config.d/50-cloud-init.conf'

patch_line() {
  local key=$1
  local value=$2
  # If key exists (commented or not) → replace line
  if grep -qiE "^\s*#?\s*${key}\s+" "$SSHCFG"; then
    sed -Ei "s|^\s*#?\s*${key}\s+.*|${key} ${value}|I" "$SSHCFG"
  else                # key missing → append
    echo "${key} ${value}" >>"$SSHCFG"
  fi
}

patch_line "PasswordAuthentication" "no"
patch_line "PermitRootLogin" "no"
patch_line "UsePAM" "no"

if [[ -f $50CLOUDINIT ]]; then
    rm -f "$50CLOUDINIT"
fi

/usr/sbin/sshd -t
systemctl restart ssh
