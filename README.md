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

### Manual Deployment

Set variables in each environment as needed, and run Terraform from the respective directory:

```sh
cd terraform/Webapplication/dev
terraform init
terraform apply
```

### Deploying with GitLab CI/CD

Deployment can be automated using the provided `.gitlab-ci.yml` file. The pipeline is designed to detect the target environment (`dev`, `stage`, or `prod`) using the `CI_ENVIRONMENT_NAME` variable and will execute Terraform commands in the corresponding folder.

**To deploy to a specific environment:**
1. Trigger the pipeline in GitLab and set the environment (e.g., `dev`, `stage`, or `prod`) as the value for `CI_ENVIRONMENT_NAME`.
2. The pipeline will automatically:
    - Change directory to `terraform/Webapplication/<environment>`
    - Run `terraform init`, `terraform validate`, `terraform plan`, and (manually approved) `terraform apply` for that environment

**Example:**
- To deploy to `stage`, trigger the pipeline with `CI_ENVIRONMENT_NAME=stage`.
- The pipeline jobs will execute Terraform commands in `terraform/Webapplication/stage`.

> **Note:** The `apply` stage is manual for safety and must be approved in the GitLab UI.

For more details, see the `.gitlab-ci.yml` file