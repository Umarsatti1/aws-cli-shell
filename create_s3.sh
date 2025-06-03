#!/bin/bash
set -euo pipefail

# Check if the AWS CLI v2 is installed or not
check_awscli() {
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI is not installed. Installing..."
        install_awscli # Call the install_awscli() function
    fi
}

# Install AWS CLI v2
install_awscli() {
    echo "Installing AWS CLI v2..."
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo apt-get install -y unzip &> /dev/null
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
    aws --version
}

# Check if the bucket exists
check_bucket_exists() {
    local bucket_name="$1"
    if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        echo "Bucket '$bucket_name' already exists."
        return 0
    else
        return 1
    fi
}

# Create an S3 bucket
create_bucket() {
    local bucket_name="$1"
    local region="$2"

    if check_bucket_exists "$bucket_name"; then
        echo "Skipping creation."
        return
    fi

    echo "Creating S3 bucket '$bucket_name' in region '$region'..."
    aws s3api create-bucket \
        --bucket "$bucket_name" \
        --region "$region" \
        --create-bucket-configuration LocationConstraint="$region"

    echo "Bucket '$bucket_name' created successfully."
}

main() {
    check_awscli

    # Set your values here or pass them in as arguments
    BUCKET_NAME="$1"   # Accepts as first argument
    REGION="$2"        # Accepts as second argument

    if [[ -z "$BUCKET_NAME" ]]; then
        echo "Error: Bucket name is required."
        echo "Usage: ./create_s3_bucket.sh <bucket-name> [region]"
        exit 1
    fi

    create_bucket "$BUCKET_NAME" "$REGION"
}

main "$@"
