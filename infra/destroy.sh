#!/bin/bash

set -e

echo "Destroying EKS..."
cd 90-eks
terraform init
terraform destroy -auto-approve
cd ..

echo "Destroying Frontend ALB..."
cd 80-frontend-alb
terraform init
terraform destroy -auto-approve
cd ..

echo "Destroying ACM..."
cd 70-acm
terraform init
terraform destroy -auto-approve
cd ..

echo "Destroying ECR..."
cd 40-ecr
terraform init
terraform destroy -auto-approve
cd ..

echo "Destroying SG Rules..."
cd 30-sg-rules
terraform init
terraform destroy -auto-approve
cd ..

echo "Destroying Bastion..."
cd 20-bastion
terraform init
terraform destroy -auto-approve
cd ..

echo "Destroying Security Groups..."
cd 10-sg
terraform init
terraform destroy -auto-approve
cd ..

echo "Destroying VPC..."
cd 00-vpc
terraform init
terraform destroy -auto-approve
cd ..

echo "Infrastructure destroy completed."
