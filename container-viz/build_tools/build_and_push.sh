#!/usr/bin/env bash

# This script shows how to build the Docker image and push it to ECR to be ready for use
# by SageMaker.

# The argument to this script is the image name. This will be used as the image on the local
# machine and combined with the account and region to form the repository name for ECR.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/set_env.sh

image=$IMAGE_NAME
tag=$IMAGE_TAG

# Get the account number associated with the current IAM credentials
account=$(aws sts get-caller-identity --query Account --output text)

if [ $? -ne 0 ]
then
    exit 255
fi


# Get the region defined in the current configuration (default to us-west-2 if none defined)
region=$(aws configure get region)
region=${region:-us-west-2}


fullname="${account}.dkr.ecr.${region}.amazonaws.com/${image}:${tag}"

# If the repository doesn't exist in ECR, create it.

aws ecr describe-repositories --region ${region} --repository-names "${image}" > /dev/null 2>&1

if [ $? -ne 0 ]
then
    aws ecr create-repository --region ${region} --repository-name "${image}" > /dev/null
fi


# Build the docker image locally with the image name and then push it to ECR
# with the full name.

# Get the login command from ECR and execute it directly
$(aws ecr get-login --no-include-email --region us-west-2  --registry-ids 763104351884)
docker build  -t ${image} $DIR/..
docker tag ${image} ${fullname}

# Get the login command from ECR and execute it directly
$(aws ecr get-login --region ${region} --no-include-email)
docker push ${fullname}
