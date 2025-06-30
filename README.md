# Webapplication Terraform Project Structure

This directory contains Terraform code for provisioning the AWS infrastructure for the web application, separated by environment.

## Structure

```
terraform/Webapplication/
  ├── dev/
  ├── stage/
  └── prod/
```

Each environment contains:
- `main.tf`: Main Terraform configuration (Route53, Global Accelerator, ALB, ECS, CloudWatch Log Group)
- `variables.tf`: Input variables
- `outputs.tf`: Output values
- `backend.tf`: (Optional) Remote state backend config

## Components
- **Route53**: DNS management for the app domain
- **Global Accelerator**: Global performance and availability
- **ALB**: Application Load Balancer for ECS services
- **ECS**: Cluster to run containers
- **CloudWatch Log Group**: Centralized logging

## Usage

Set variables in each environment as needed, and run Terraform from the respective directory:

```sh
cd terraform/Webapplication/dev
terraform init
terraform apply
```