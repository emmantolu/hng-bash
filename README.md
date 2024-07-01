Managing user accounts is a critical task for SysOps engineers. The script [create_users.sh](https://github.com/emmantolu/hng-bash) automates the process of creating new users, setting up their home directories, generating random passwords, and logging all actions. This article explains the reasoning behind each of the 9 steps.

This script is the result of a task under the DevOps Engineering program of HNG Internship. You can learn more about the HNG Internship and their valuable programs [here](https://hng.tech/internship) and [here](https://hng.tech/hire).

#### Prerequisites

- Basic understanding of shell scripting.
- Root or sudo access to the server.

#### Script Breakdown

1. Input File Validation:

```
if [ $# -ne 1 ]; then
	echo "Usage: $0 <user_file>"
	exit 1
fi

user_file=$1

if [ ! -f $user_file ]; then
	echo "User file not found!"
	exit 1
fi
```
As the script runs by reading a file passed as an argument during it's execution, we begin by checking that the file (which contains the list of users and groups to be created) has been passed and that it actually exists on the server. 

2. Logging Function:
```
    logging() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
    }
```  
The logging function logs actions with timestamps to facilitate auditing and troubleshooting.

3. Setting Up Log and Password Files:

```
log_file="/var/log/user_management.log"
secure_dir="/var/secure/"
password_file="/var/secure/user_passwords.txt"

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

create_secure_dir
touch $log_file
touch $password_file

chmod 600 $password_file
```
We then define the log and password file paths, ensuring they exist, and setting secure permissions for the password file.

4. Password Generation Function:

```
generate_password() {
	openssl rand -base64 12
}
```
The generate_password function generates a random password using OpenSSL for secure user authentication.

5. Reading and Processing the Input File:

```
while IFS=';' read -r user groups; do
	user=$(echo $user | xargs)
	groups=$(echo $groups | xargs)
```
This reads each line from the input file, stripping any leading/trailing whitespace from usernames and groups.

6. User and Group Creation:

```
	if id "$user" &>/dev/null; then
		logging "User $user already exists. Skipping..."
		continue
	fi

	if ! getent group "$user" >/dev/null; then
		groupadd "$user"
		logging "Group $user created."
	fi

	useradd -m -g "$user" -s /bin/bash "$user"
	logging "User $user created with home directory."
```
We check if the user exists, create a user-specific group if not already present, and then create the user with a home directory.

7. Password Assignment:

```
	password=$(generate_password)
	echo "$user:$password" | chpasswd
	echo "$user:$password" >> $password_file
	logging "Password set for user $user."
```
Here we assign a random password to the user and log it securely.

8. Adding Users to Groups:

```
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
```
The user is added to any additional groups, creating those groups if they don't exist.

9. Setting Home Directory Permissions:

```
	chmod 755 "/home/$user"
	chown "$user:$user" "/home/$user"
	logging "Permissions set for home directory of $user."
```
Secure permissions are then set for the user's home directory.

#### Conclusion
The create_users.sh script simplifies user account management, ensuring secure and consistent setup across systems. By automating user creation, group assignments, and logging, SysOps engineers can save time and reduce errors.

For more insights into the HNG Internship and its offerings, visit their [internship page](https://hng.tech/internship) and [premium services](https://hng.tech/premium).
