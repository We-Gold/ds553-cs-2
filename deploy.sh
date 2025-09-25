#! /bin/bash

PORT=22003
DEPLOY_PORT=8003
MACHINE=paffenroth-23.dyn.wpi.edu
STUDENT_ADMIN_KEY_PATH=$HOME/.ssh

# Clean up from previous runs
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[${MACHINE}]:${PORT}"

rm -rf tmp

# Create a temporary directory
mkdir tmp

# Copy the .env file to the temporary directory
cp .env tmp

# copy the key to the temporary directory
cp ${STUDENT_ADMIN_KEY_PATH}/student-admin_key* tmp

# Copy public keys to the temporary directory
cp public_keys tmp

# Change the premissions of the directory
chmod 700 tmp

# Change to the temporary directory
cd tmp

# Set the permissions of the key
chmod 600 student-admin_key*

# Create a unique key
rm -f autokey*
ssh-keygen -f autokey -t ed25519 -N ""

# Insert the key into the authorized_keys file on the server
# and insert the user's public keys
cat autokey.pub > authorized_keys
cat public_keys >> authorized_keys
cat student-admin_key.pub >> authorized_keys #TEMPORARY

chmod 600 authorized_keys

echo "checking that the authorized_keys file is correct"
ls -l authorized_keys
cat authorized_keys

# Copy the authorized_keys file to the server
scp -i student-admin_key -P ${PORT} -o StrictHostKeyChecking=no authorized_keys student-admin@${MACHINE}:~/.ssh/

# Add the key to the ssh-agent
eval "$(ssh-agent -s)"
ssh-add autokey

# # Check the key file on the server
echo "checking that the authorized_keys file is correct"
ssh -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE} "cat ~/.ssh/authorized_keys"

# clone the repo
git clone https://github.com/We-Gold/ds553-cs-2.git

# Copy the files to the server
scp -P ${PORT} -o StrictHostKeyChecking=no -r ds553-cs-2 student-admin@${MACHINE}:~/

# Copy the environment variable file to the server
scp -P ${PORT} -o StrictHostKeyChecking=no .env student-admin@${MACHINE}:~/ds553-cs-2/.env

COMMAND="ssh -i autokey -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE}"

${COMMAND} "ls ds553-cs-2"
${COMMAND} "sudo apt install -qq -y python3-venv"
${COMMAND} "sudo apt install -qq -y ffmpeg"
${COMMAND} "cd ds553-cs-2 && python3 -m venv venv"
${COMMAND} "cd ds553-cs-2 && source venv/bin/activate && pip install -r requirements.txt"
${COMMAND} "nohup ds553-cs-2/venv/bin/python3 ds553-cs-2/app.py > log.txt 2>&1 &"

echo "Deployment complete. You can access the application at https://${MACHINE}:${DEPLOY_PORT}"
