#!/bin/bash
set -euo pipefail

# Check if the AWS CLI v2 is installed or not
check_awscli() {
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI is not installed. Please install it first." >&2
        return 1
    fi
}

# Install AWS CLI v2
install_awscli() {
    echo "Installing AWS CLI v2 on Linux..."
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo apt-get install -y unzip &> /dev/null
    unzip -q awscliv2.zip
    sudo ./aws/install
    aws --version
    rm -rf awscliv2.zip ./aws
}

# Wait for the EC2 instance to be in running state
wait_for_instance() {
    local instance_id="$1"
    echo "Waiting for instance $instance_id to be in running state..."

    while true; do
        state=$(aws ec2 describe-instances --instance-ids "$instance_id" \
            --query 'Reservations[0].Instances[0].State.Name' \
            --output text)
        if [[ "$state" == "running" ]]; then
            echo "Instance $instance_id is now running."
            break
        fi
        sleep 15
    done
}

# Create EC2 instance using arguments
create_ec2_instance() {
    local ami_id="$1"
    local instance_type="$2"
    local key_name="$3"
    local subnet_id="$4"
    local security_group_ids="$5"
    local instance_name="$6"

    instance_id=$(aws ec2 run-instances \
        --image-id "$ami_id" \
        --instance-type "$instance_type" \
        --key-name "$key_name" \
        --subnet-id "$subnet_id" \
        --security-group-ids "$security_group_ids" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]" \
        --query 'Instances[0].InstanceId' \
        --region us-east-1 \
        --output text
    )

    if [[ -z "$instance_id" ]]; then
        echo "Failed to create EC2 instance." >&2
        exit 1
    fi

    echo "Instance $instance_id created successfully."
    wait_for_instance "$instance_id"
}

main() {
    if ! check_awscli; then
        install_awscli || exit 1
    fi

    if [[ $# -ne 2 ]]; then
        echo "Usage: $0 <Instance-Name> <Instance-Type>"
        echo "Example: $0 MyAppServer t2.micro"
        exit 1
    fi

    INSTANCE_NAME="$1"
    INSTANCE_TYPE="$2"

    echo "Creating EC2 instance named '$INSTANCE_NAME' of type '$INSTANCE_TYPE' in us-east-1 region..."

    # Static values — update based on your environment
    AMI_ID="ami-0abcdef1234567890"  # Replace with valid AMI ID
    KEY_NAME="my-key"               # Replace with your EC2 key pair name
    SUBNET_ID="subnet-0123456789abcdef0"  # Replace with your subnet ID
    SECURITY_GROUP_IDS="sg-0123456789abcdef0"  # Replace with your security group ID(s)

    create_ec2_instance "$AMI_ID" "$INSTANCE_TYPE" "$KEY_NAME" "$SUBNET_ID" "$SECURITY_GROUP_IDS" "$INSTANCE_NAME"

    echo "EC2 instance '$INSTANCE_NAME' created successfully."
}

main "$@"