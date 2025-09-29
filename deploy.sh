#! /bin/bash

PORT=22003
DEPLOY_PORT=8003
GRADIO_PORT=7860
MACHINE=paffenroth-23.dyn.wpi.edu
KEY_PATH=$HOME/.ssh

DEFAULT_KEY="student-admin_key"
USE_DEFAULT_FOR_DEPLOY=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--default)
            USE_DEFAULT_FOR_DEPLOY=true
            shift
            ;;
        *)
            # If not a flag, treat as key name
            SSH_KEY_NAME="$1"
            shift
            ;;
    esac
done

# Check if key name was provided
if [ -z "$SSH_KEY_NAME" ]; then
    echo "Error: SSH key name is required"
    echo "Usage: $0 [-d|--default] <key_name>"
    echo "  -d, --default: Use default key for deployment operations"
    exit 1
fi

# Determine which key to use for deployment
if [ "$USE_DEFAULT_FOR_DEPLOY" = true ]; then
    DEPLOY_KEY="$DEFAULT_KEY"
    echo "Using SSH key: ${SSH_KEY_NAME} (with default key ${DEPLOY_KEY} for deployment)"
else
    DEPLOY_KEY="$SSH_KEY_NAME"
    echo "Using SSH key: ${SSH_KEY_NAME} (for all operations)"
fi

# Clean up from previous runs
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[${MACHINE}]:${PORT}"

rm -rf tmp

# Create a temporary directory
mkdir tmp

# Copy the .env file to the temporary directory
cp .env tmp

# copy the key to the temporary directory
# Note: we want this to fail if the key is not found
cp ${KEY_PATH}/${SSH_KEY_NAME} tmp

if [ "$USE_DEFAULT_FOR_DEPLOY" = true ]; then
    cp ${KEY_PATH}/${DEFAULT_KEY} tmp
fi

# Add the key to the ssh-agent
eval "$(ssh-agent -s)"
ssh-add ${KEY_PATH}/${SSH_KEY_NAME}

# Copy public keys to the temporary directory
cp public_keys tmp

# Change the premissions of the directory
chmod 700 tmp

# Change to the temporary directory
cd tmp

# Insert the key into the authorized_keys file on the server
# and insert the user's public keys
cat ${KEY_PATH}/${SSH_KEY_NAME}.pub > authorized_keys
cat public_keys >> authorized_keys

chmod 600 authorized_keys

echo "checking that the authorized_keys file is correct"
ls -l authorized_keys
cat authorized_keys

# Assumes we are in the tmp directory
deploy_application() {
    # Copy the authorized_keys file to the server
    if [ "$USE_DEFAULT_FOR_DEPLOY" = true ]; then
        scp -i ${DEFAULT_KEY} -P ${PORT} -o StrictHostKeyChecking=no authorized_keys student-admin@${MACHINE}:~/.ssh/
    else
        scp -P ${PORT} -o StrictHostKeyChecking=no authorized_keys student-admin@${MACHINE}:~/.ssh/
    fi

    # Check the key file on the server
    echo "checking that the authorized_keys file is correct"
    ssh -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE} "cat ~/.ssh/authorized_keys"

    # Remove the repo from this folder if it exists
    rm -rf ds553-cs-2

    # clone the repo
    git clone https://github.com/We-Gold/ds553-cs-2.git

    # Copy the files to the server
    scp -P ${PORT} -o StrictHostKeyChecking=no -r ds553-cs-2 student-admin@${MACHINE}:~/

    # Copy the environment variable file to the server
    scp -P ${PORT} -o StrictHostKeyChecking=no .env student-admin@${MACHINE}:~/ds553-cs-2/.env

    COMMAND="ssh -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE}"

    ${COMMAND} "lsof -t -i:${GRADIO_PORT} | xargs -r kill" # kill any existing gradio processes
    ${COMMAND} "ls ds553-cs-2"
    ${COMMAND} "sudo apt install -qq -y python3-venv"
    ${COMMAND} "sudo apt install -qq -y ffmpeg"
    ${COMMAND} "cd ds553-cs-2 && python3 -m venv venv"
    ${COMMAND} "cd ds553-cs-2 && source venv/bin/activate && pip install -r requirements.txt"
    ${COMMAND} "nohup ds553-cs-2/venv/bin/python3 ds553-cs-2/app.py > log.txt 2>&1 &"

    echo "Deployment complete. You can access the application at http://${MACHINE}:${DEPLOY_PORT}"
}

deploy_application

echo "Starting server monitoring..."

sleep 10

while true; do
    # Check if the product is reachable using curl
    curl -I --max-time 5 http://$MACHINE:$DEPLOY_PORT/ >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "$(date): Server is down. Redeploying..."
        deploy_application
    else
        echo "$(date): Server is active."
    fi
    sleep 300  # Wait for 5 minutes
done