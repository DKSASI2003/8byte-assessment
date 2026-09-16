# Challenges and Trade-offs

This project was intentionally implemented as a small, cost-conscious skeleton of a production deployment platform. Because the assessment had a limited scope and timeline, I prioritized working infrastructure, repeatable deployment, security controls, and observability over building every production-grade capability.

## Infrastructure

### Shared RDS instance

Staging and production currently use the same PostgreSQL RDS instance. This reduced cost and infrastructure complexity, but it is not appropriate for production because the environments are not fully isolated. A production implementation should use separate RDS instances, databases, credentials, subnet groups, and security boundaries for staging and production.

The current database does have automated backups enabled with seven-day retention. The next step would be to define separate backup, restore, and disaster-recovery policies for each environment.

### Simple application architecture

The application is a small TODO service, so it does not require a full three-tier architecture for this assessment. The current design uses an Application Load Balancer, EC2, and RDS. A larger system would separate the presentation, application, and data layers more explicitly and introduce services such as a queue, cache, or worker tier where appropriate.

### EC2 instead of ECS or EKS

I used EC2 because it was faster to implement and has a lower baseline cost for a small workload. For a production platform, ECS or EKS would provide better container scheduling, rolling deployments, health management, scaling, and workload isolation. ECS on Fargate would also remove much of the host-management responsibility without requiring Kubernetes operations.

### Terraform structure

The Terraform configuration is intentionally simple and is not fully modularized. In my current organization, Terragrunt is used to compose reusable Terraform components across environments. A future version of this project could split networking, compute, database, observability, and application delivery into reusable modules with separate staging and production state.

### HTTPS and domain management

No domain name was available for this assessment, so I could not provision an ACM certificate and configure HTTPS. The current ALB listeners use HTTP, which is not suitable for production. A production deployment should use:

- A registered domain and Route 53 records
- ACM certificates
- HTTPS listeners with HTTP-to-HTTPS redirection
- Secure cookies and appropriate security headers

## CI/CD

### GitHub Actions instead of Jenkins and Argo CD

My current organization uses Jenkins for CI and Argo CD for CD. I chose GitHub Actions for this assessment because setting up and securing Jenkins, a Jenkins agent, and Argo CD would have added significant infrastructure outside the application requirements.

The workflow still follows the same core delivery principles:

- Test pull requests
- Scan dependencies and container images
- Build and push images to ECR after a merge to `main`
- Deploy to staging automatically
- Require approval before production deployment
- Send email notifications when the pipeline fails

### Secrets and environments

One early challenge was understanding the difference between repository secrets and environment secrets/variables in GitHub Actions. The workflow initially could not retrieve some values because they were configured in a different scope than the job expected. I resolved this by explicitly configuring the required repository and environment values and by using protected production environments for the approval gate.

The deployment workflow uses AWS Systems Manager instead of distributing PEM keys to the CI runner or storing SSH credentials. SSM is a better fit here because it uses the EC2 instance role and avoids managing long-lived private keys.

### SSM Agent and bootstrap issues

The EC2 bootstrap initially had problems installing the SSM Agent because of Amazon Linux package and version differences. I added a fallback installation path using the regional SSM Agent package and verified connectivity through SSM. This also highlighted an important operational distinction: EC2 user data runs during initial instance creation, while later configuration changes require SSM, a configuration-management tool, or instance replacement.

The CloudWatch Agent configuration is now reconciled through Terraform-managed SSM associations for both staging and production, while user data still bootstraps newly created instances.

### Test coverage

The test suite covers the core Flask routes and database interaction paths with mocked connections. Because the service is small, the tests are intentionally focused. I did not add a full integration environment, EC2 infrastructure tests, or end-to-end tests against a deployed RDS instance within the assessment timeframe.

A production test strategy should add:

- Integration tests against an isolated database
- API contract and validation tests
- Container smoke tests
- Terraform plan and policy checks
- Deployment health checks after staging deployment
- End-to-end tests through each ALB

## Monitoring and Logging

### AWS-native monitoring

I initially considered Grafana Cloud (where trial version is avaliable for 30 days) because I am familiar with the Grafana and Prometheus ecosystem. To keep the assessment focused and avoid introducing another hosted platform, I used AWS-native services instead:

- CloudWatch Agent for EC2 CPU, memory, disk, network, and process metrics
- CloudWatch Logs for application, system, and nginx access logs
- ALB metrics for request count, response time, and target errors
- RDS metrics for CPU, connections, and storage
- Terraform-managed infrastructure and application dashboards
- S3 for ALB access logs

This approach reduces the number of external systems to operate and integrates naturally with the AWS deployment.

### Log collection troubleshooting

A key logging issue occurred because the CloudWatch Agent was configured to read `/var/log/nginx/access.log` on the EC2 host, while nginx was running inside the Docker container. The host and container therefore had different filesystems. The deployment was updated to mount `/var/log/nginx` from the host into the container so the agent can collect nginx access logs into the `access-logs` CloudWatch log group.

Similarly, the CloudWatch Agent configuration needed to be explicitly copied to existing instances. Updating a file in the repository does not update an already-running EC2 instance automatically. Terraform-managed SSM associations now distribute and reload the configuration on both environments.

## Security Improvements for Production

The project includes IAM roles, private RDS networking, SSM-based access, vulnerability scanning, encrypted Terraform state, and protected production deployment. There are still important hardening tasks:

- Restrict EC2 SSH access instead of allowing `0.0.0.0/0`, or remove SSH and use SSM Session Manager only.
- Replace the broad `SecretsManagerReadWrite` policy with a resource-scoped `secretsmanager:GetSecretValue` policy.
- Use HTTPS everywhere and configure ACM certificates.
- Separate staging and production databases and credentials.
- Enable RDS deletion protection and require final snapshots for production.
- Use short-lived or federated AWS credentials for CI rather than long-lived access keys.
- Add WAF, rate limiting, stronger security headers, and centralized alerting where required.

## Summary

The final implementation is intentionally not presented as a complete production platform. It is a working, cost-effective foundation that demonstrates infrastructure as code, environment separation, container delivery, secrets management, SSM deployment, vulnerability scanning, monitoring, centralized logging, backups, and approval-based promotion.

The main lesson from the implementation was that production readiness is not only about adding services. It also depends on environment isolation, least-privilege access, secure transport, repeatable configuration management, tested recovery procedures, and meaningful operational alerts. Those are the areas I would prioritize in the next iteration.
