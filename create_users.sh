#!/bin/bash

# Date: 01/07/2024
# Author: Emmanuel Toluwalase

: <<'END_COMMENT'
 This script reads a file containing usernames and group names (where each line is formatted as user;groups) and creates them, 
 sets up home directories with appropriate permissions and ownership, generates random passwords for the users, and logs all actions 
 to /var/log/user_management.log. The generated passwords are stored in /var/secure/user_passwords.txt.

 USAGE: sudo ./create_users.sh

END_COMMENT

# Check if the input file is provided
if [ $# -ne 1 ]; then
	echo "Usage: $0 <user_file>"
	exit 1
fi

user_file=$1

# Ensure the input file exists
if [ ! -f $user_file ]; then
	echo "User file not found!"
	exit 1
fi

# Function to log all actions
logging() {
	timestamp=$(date +"%Y-%m-%d %H:%M:%S")
	echo "[$timestamp] - $1" >> $log_file
}

# Declare log and password file paths
log_file="/var/log/user_management.log"
secure_dir="/var/secure/"
password_file="/var/secure/user_passwords.txt"

# Function to check and/or create secure directory to store user passwords textfile
create_secure_dir() {
	if [ ! -e "$secure_dir" ]; then
		mkdir -p "$secure_dir"
		if [ $? -ne 0 ]; then
			logging "ERROR: Failed to create directory $secure_dir"
			exit 1
		fi
		logging "Created directory: $secure_dir"
	fi
}

# Ensure the log and password files exist
create_secure_dir
touch $log_file
touch $password_file

# Set proper permissions for password file
chmod 600 $password_file



# Function to generate a random password
generate_password() {
	openssl rand -base64 12
}

# Read the user file line by line
while IFS=';' read -r user groups; do
	# Remove leading/trailing whitespace
	user=$(echo $user | xargs)
	groups=$(echo $groups | xargs)

	# Check if user already exists
	if id "$user" &>/dev/null; then
		logging "User $user already exists. Skipping..."
		continue
	fi

	# Create user-specific group
	if ! getent group "$user" >/dev/null; then
		groupadd "$user"
		logging "Group $user created."
	fi

	# Create the user with a home directory and user-specific group
	useradd -m -g "$user" -s /bin/bash "$user"
	logging "User $user created with home directory."

	# Generate a random password for the user
	password=$(generate_password)
	echo "$user:$password" | chpasswd
	echo "$user:$password" >> $password_file
	logging "Password set for user $user."

	# Add user to additional groups
	IFS=',' read -ra group_array <<< "$groups"
	for group in "${group_array[@]}"; do
		group=$(echo $group | xargs)  # Remove whitespace
		if ! getent group "$group" >/dev/null; then
			groupadd "$group"
			logging "Group $group created."
		fi
		usermod -aG "$group" "$user"
		logging "User $user added to group $group."
	done

	# Set appropriate permissions for the home directory
	chmod 755 "/home/$user"
	chown "$user:$user" "/home/$user"
	logging "Permissions set for home directory of $user."

done < "$user_file"

echo "User creation process completed. Check $log_file for details."
