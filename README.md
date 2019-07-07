# 1. Create a IAM User for Terraform in the AWS console
...with Programmatic Access only and with the following permissions:

- `arn:aws:iam::aws:policy/AmazonS3FullAccess`
- `arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess`
- `arn:aws:iam::aws:policy/IAMFullAccess`
- `arn:aws:iam::aws:policy/AmazonRoute53FullAccess`
- `arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess`
- `arn:aws:iam::aws:policy/AmazonRDSFullAccess`
- `arn:aws:iam::aws:policy/AmazonEC2FullAccess`
- `arn:aws:iam::aws:policy/AmazonECS_FullAccess`
- `arn:aws:iam::aws:policy/CloudWatchFullAccess`
- `arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess`


# 2. Display access keys for the terraform user (do not download!)
```
export PROJECT_NAME=your_project_name_here

export PROJECT_ENVIRONMENT=staging

aws --profile $PROJECT_NAME.$PROJECT_ENVIRONMENT configure
```

Save the below function into your terminal to easily load an AWS profile in a terminal instance (optional):
```
awsprofile() { export AWS_ACCESS_KEY_ID=$(aws --profile $1 configure get aws_access_key_id) && export AWS_SECRET_ACCESS_KEY=$(aws --profile $1 configure get aws_secret_access_key); }

awsprofile $PROJECT_NAME.$PROJECT_ENVIRONMENT
```

# 3. For each new project:

...prepare the project for terraforming

## Create an S3 bucket
```
aws s3 mb s3://$PROJECT_ENVIRONMENT.$PROJECT_NAME.terraform

aws s3api put-bucket-encryption --bucket $PROJECT_ENVIRONMENT.$PROJECT_NAME.terraform --server-side-encryption-configuration '{ "Rules": [ { "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" } } ] }'

aws s3api put-public-access-block --bucket $PROJECT_ENVIRONMENT.$PROJECT_NAME.terraform --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws s3api put-bucket-versioning --bucket $PROJECT_ENVIRONMENT.$PROJECT_NAME.terraform --versioning-configuration MFADelete=Disabled,Status=Enabled
```

## Create the DynamoDB database
```
aws dynamodb create-table --region eu-west-2 --table-name terraform_locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
```

## Set up the Terraform project
```
export TF_VAR_project_name=$PROJECT_NAME

terraform init

terraform apply
```

# Build and deploy your Docker images manually (optional)
```
eval $(aws ecr get-login --registry-ids $(terraform output account_id) --no-include-email)

docker build .. --tag $(terraform output ecr_laravel_repository_uri) && docker push $(terraform output ecr_laravel_repository_uri)

docker build .. -f Dockerfile-nginx --tag $(terraform output ecr_nginx_repository_uri) && docker push $(terraform output ecr_nginx_repository_uri)
```

# SSH tunnelling into the database through the EC2 bastion (optional)
```
aws ec2 run-instances --image-id $(terraform output ec2_ami_id) --count 1 --instance-type t2.micro --key-name $(terraform output ec2_key_name) --security-group-ids $(terraform output ec2_security_group_id) --subnet-id $(terraform output ec2_public_subnet_id) --associate-public-ip-address | grep InstanceId

aws ec2 describe-instances --instance-ids xxxx | grep PublicIpAddress
```

```
ssh ubuntu@xxxxx -i $(terraform output ec2_ssh_key_path) -L 3306:$(terraform output aurora_endpoint):3306
```

Then connect using your favourite MySQL client
```
mysql -u$(terraform output aurora_db_username) -p$(terraform output aurora_master_password) -h 127.0.0.1 -D $(terraform output aurora_db_name)
```

```
aws ec2 terminate-instances --instance-ids xxxx
```

// TODO workers and cron