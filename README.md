# 8Byte Task API

AWS infrastructure and CI/CD deployment for a Flask task API running on Amazon Linux EC2 behind separate staging and production Application Load Balancers.

## Architecture

```text
Internet
	 |
	 +--> Staging ALB --> Staging EC2 --> RDS PostgreSQL
	 |
	 +--> Production ALB --> Production EC2 --> RDS PostgreSQL
	 |
	 +--> ECR
	 +--> Secrets Manager
	 +--> CloudWatch
```

The main components are:

- VPC with public subnets for ALBs and EC2 and private subnets for RDS.
- One EC2 instance for staging and one for production.
- One ALB and target group per environment.
- Amazon RDS for PostgreSQL in private subnets.
- Amazon ECR for Docker images.
- AWS Systems Manager for deployments and CloudWatch Agent configuration.
- CloudWatch dashboards, metrics, application logs, system logs, and nginx access logs.
- S3 for ALB access logs.

## Prerequisites

Install and configure:

- Terraform >= 1.5
- AWS CLI
- Docker, if building locally
- An AWS identity with permissions to manage the resources in `terraform/`

The AWS CLI must be configured for `ap-south-1`:

```bash
aws configure
aws sts get-caller-identity
```

## Secret Management

Database credentials are stored in AWS Secrets Manager. Terraform reads the existing secret named:

```text
8byte-postgres-secret
```

The secret must contain JSON fields matching the application connection code:

```json
{
	"host": "postgres-host",
	"username": "app-user",
	"password": "strong-password",
	"dbname": "appdb"
}
```

Create the secret before applying Terraform if it does not exist:

```bash
aws secretsmanager create-secret \
	--name 8byte-postgres-secret \
	--secret-string '{"host":"placeholder","username":"app-user","password":"change-me","dbname":"appdb"}' \
	--region ap-south-1
```

Update the secret with the actual RDS endpoint after the database is created. Do not commit passwords, `.tfvars` credentials, or AWS keys to Git.

The EC2 instance role currently uses `SecretsManagerReadWrite` so the application can read the secret. For production, replace this broad managed policy with a least-privilege policy allowing only `secretsmanager:GetSecretValue` for `8byte-postgres-secret`.

## Terraform Setup

The Terraform backend expects these resources to exist before initialization:

- S3 bucket: `8byte-tf-state`
- DynamoDB table: `terraform-locks`
- Region: `ap-south-1`

The S3 backend uses encryption and DynamoDB locking. Initialize and review the infrastructure:

```bash
cd terraform
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Apply the infrastructure after reviewing the plan:

```bash
terraform apply
```

Useful outputs:

```bash
terraform output production_alb_dns
terraform output staging_alb_dns
terraform output production_instance_id
terraform output staging_instance_id
terraform output ecr_repository_url
```

Do not use `terraform destroy` in a shared or production environment without reviewing its impact. The current RDS configuration has `skip_final_snapshot = true`, so change that setting before any destructive operation if database recovery is required.

## Running the Application Locally

Install dependencies and run the tests:

```bash
pip install -r app/requirements.txt
python -m pytest -q
```

Build and run the container locally:

```bash
docker build -t 8byte-app:local ./app
docker run --rm -p 8080:80 8byte-app:local
```

Test the application:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/
```

## CI/CD

The GitHub Actions workflow in `.github/workflows/deploy.yaml` runs:

### Pull requests to `main`

- Unit and integration tests with pytest
- Python dependency audit with `pip-audit`
- Filesystem vulnerability scan with Trivy

### Pushes to `main`

1. Run the same tests and scans.
2. Build the Docker image.
3. Scan the image with Trivy.
4. Push the image to ECR using the commit SHA as its tag.
5. Deploy to staging through SSM.
6. Wait for approval on the protected `production` environment.
7. Deploy the same image to production after approval.

Configure these repository variables:

```text
ECR_REPOSITORY
STAGING_INSTANCE_ID
PRODUCTION_INSTANCE_ID
```

Configure these repository secrets:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
SMTP_SERVER
SMTP_PORT
SMTP_USERNAME
SMTP_PASSWORD
MAIL_TO
```

Configure required reviewers under **Settings -> Environments -> production** to enable the manual production approval gate.

## Monitoring and Logging

CloudWatch Agent runs on both EC2 instances and publishes the `8Byte` namespace metrics:

- CPU, memory, disk, network, disk I/O, swap, TCP, and process metrics.
- System logs from `/var/log/messages` to `ec2-system`.
- nginx access logs from `/var/log/nginx/access.log` to `access-logs`.

Docker stdout and stderr are sent to the `8byte-app` CloudWatch log group using the `awslogs` Docker driver. ALB access logs are stored in the encrypted S3 bucket configured by `alb_logs_bucket_name`.

The dashboards are managed by Terraform:

- `8Byte-Infrastructure-Dashboard`
- `8Byte-Application-Dashboard`

## Backup Strategy

RDS automated backups are enabled with a seven-day retention period:

```hcl
backup_retention_period = 7
```

For production, consider enabling deletion protection and setting `skip_final_snapshot = false`. Test restore procedures regularly; a backup strategy is incomplete until restoration has been verified.

Terraform state is protected with encrypted S3 storage and DynamoDB locking. The ALB log bucket uses SSE-S3 encryption and a 90-day lifecycle policy.

## Security Considerations

- RDS is not publicly accessible and accepts PostgreSQL traffic only from the EC2 security group.
- EC2 HTTP traffic is accepted only from the ALB security group.
- ALB ingress is restricted to the configured client CIDR in `terraform/security_groups.tf`.
- EC2 uses IAM roles for ECR, SSM, CloudWatch, and Secrets Manager access instead of static AWS credentials.
- Production deployment requires GitHub Environment approval.
- Container and filesystem vulnerabilities are scanned before deployment.
- ALB logs are written to a private encrypted S3 bucket.
- Restrict the EC2 SSH rule from `0.0.0.0/0` to a trusted administration CIDR or remove SSH and use SSM Session Manager.
- Replace `SecretsManagerReadWrite` with a resource-scoped read-only policy.
- Store Terraform state and all credentials outside source control.

## Cost Optimization

- Staging and production use `t3.micro` EC2 and `db.t3.micro` RDS defaults for a small assessment workload.
- EBS uses `gp3` volumes with a 20 GB default size.
- CloudWatch log groups retain logs for 30 days.
- ALB logs expire from S3 after 90 days.
- ECR lifecycle rules retain only the latest ten images.
- Docker images are tagged with immutable commit SHA values, making cleanup predictable.
- Use AWS Budgets and CloudWatch billing alerts before increasing instance or database sizes.
- For larger workloads, evaluate autoscaling, reserved capacity, and separate production sizing rather than scaling both environments equally.
