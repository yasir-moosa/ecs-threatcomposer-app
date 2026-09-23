# Threat Composer on ECS Fargate

Threat Composer is an open source app from AWS that helps you build out threat models, you can have a play with it yourself here: [Threat Composer Tool](https://awslabs.github.io/threat-composer/workspaces/default/dashboard). 

I took it and deployed it the way you'd actually run something like this in a job: containerised, running on ECS Fargate, sitting behind a load balancer with a real HTTPS domain, all built with Terraform and deployed through a CI/CD pipeline with no long lived AWS keys anywhere.

URL used: `https://tm.yasirmoosa.tech`

![Threat Composer demo](images/threat-composer-gif.gif)

## Contents

- [What this actually does](#what-this-actually-does)
- [Architecture](#architecture)
- [Folder layout](#folder-layout)
- [CI/CD](#cicd)
  - [Security and code quality scanning](#security-and-code-quality-scanning)
- [Running this yourself](#running-this-yourself)
- [Tearing it down](#tearing-it-down)
- [Proof of application working](#proof-of-application-working)
- [Successful pipeline runs](#successful-pipeline-runs)
- [CloudWatch dashboard](#cloudwatch-dashboard)
- [Notes on some of the design choices](#notes-on-some-of-the-design-choices)
- [License](#license)

## What this actually does

Threat Composer runs as a Docker container inside ECS Fargate. Traffic comes in through an Application Load Balancer on port 443, gets terminated with a real ACM certificate, and gets routed to whichever Fargate task is healthy at the time. There's no server to patch or SSH into, Fargate handles the compute for you.

Everything from the VPC up is created by Terraform. Nothing was left behind from the manual "ClickOps" phase of the assignment, that infrastructure was built once by hand to understand it, then torn down and rebuilt entirely as code.

## Architecture

- A VPC spanning two Availability Zones, with public and private subnets in each
- A regional (multi-AZ) NAT Gateway so the Fargate tasks in the private subnets can pull the image from ECR and reach the internet without needing one NAT Gateway per AZ
- An Application Load Balancer in the public subnets, listening on 80 and 443
- Port 80 just redirects straight to 443, nothing serves plain HTTP
- ECS Fargate service running the Threat Composer container, in the private subnets
- ECR repository storing the built Docker image
- ACM certificate for `tm.yasirmoosa.tech`, validated automatically through a DNS record in Route53
- Route53 hosted zone and A record pointing the subdomain at the load balancer
- S3 bucket holding the Terraform remote state
- A CloudWatch dashboard (`ecs-threat-app-dashboard`) showing ECS CPU/memory, recent application logs and ALB request count/latency/5XX/healthy-host metrics in one place

![Architecture diagram](images/architecture-diagram.png)

## Folder layout

```
.
├── app/                        # the app source + Dockerfile
├── bootstrap/
│   ├── s3_backend/              # one-off: creates the S3 bucket for remote state
│   └── ecr_bootstrap/           # one-off: creates the ECR repo
├── infra/
│   ├── main.tf
│   ├── variables.tf
│   ├── .tflint.hcl              # TFLint config (AWS ruleset + Terraform best-practice rules)
│   └── modules/
│       ├── vpc/
│       ├── sg/
│       ├── alb/
│       ├── ecs/
│       ├── acm/
│       └── route53/
└── .github/
    └── workflows/
        ├── build-and-push.yml
        ├── terraform-deploy.yml
        ├── health-check.yml
        └── terraform-destroy.yml
```

## CI/CD

There are four workflows, and only one pair of them is actually chained together:

1. **Build and Push Image** runs automatically on a push that touches `app/` or the Dockerfile (or can be triggered manually). It builds the image, runs a **Trivy vulnerability scan** against it (fails the job on any CRITICAL or HIGH severity fixable CVE so a vulnerable image never reaches ECR) then tags it with the commit SHA and pushes it to ECR.
2. **Terraform Deploy** is manual only, you trigger it from the Actions tab. It's split into two jobs: `terraform-plan` runs `init` lints the Terraform code with **TFLint** (AWS ruleset + best-practice rules, non-blocking for now) then `plan`, saving the plan as an artifact; `terraform-apply` downloads that exact plan and applies it. This way what gets applied is guaranteed to be what the plan showed, not a fresh plan that might have drifted.
3. **Post-Deploy Health Check** runs automatically right after Terraform Deploy finishes successfully (or manually on its own). It waits 2 minutes for the ECS tasks to stabilize then curls the live site with up to 10 retries (30s apart) before failing, so it doesn't false-alarm on a service that's still starting up.
4. **Terraform Destroy** is manual only, and requires typing the word "destroy" into a confirmation field before it'll run anything. Same two-job pattern as Deploy: a `terraform-destroy-plan` job saves exactly what will be torn down, then `terraform-destroy-apply` destroys precisely that.

So a normal app change goes: push to main, image gets built and pushed, that's it, nothing else runs on its own. Deploying the new image into the infra is a deliberate, manual step, and once you trigger it, the health check follows automatically to confirm the site actually came back up.

None of this uses long lived AWS access keys. GitHub Actions authenticates to AWS through OIDC: AWS trusts GitHub's identity provider directly, and issues short lived credentials to a specific IAM role only when the workflow is running from this exact repo. No secrets to rotate or leak.

### Security and code quality scanning

- **Trivy** scans the built Docker image for OS and library vulnerabilities before it's pushed. Only fixable CRITICAL/HIGH findings block the pipeline, so noise from unfixable issues doesn't stall deploys.
- **TFLint** (with the AWS ruleset plugin) lints the Terraform code on every deploy for unused variables, missing provider/version constraints and AWS-specific best practices. Currently set to report-only, not blocking.
## Running this yourself

You'll need an AWS account, the AWS CLI configured, Terraform, Docker, and a domain you control in Route53 if you want the HTTPS part to work.

**1. Create the remote state bucket and ECR repo** (one time only)

```bash
cd bootstrap/s3_backend
terraform init && terraform apply

cd ../ecr_bootstrap
terraform init && terraform apply
```

**2. Set up the OIDC identity provider and IAM role in AWS**, so GitHub Actions can deploy without static keys. This is a one time manual step done through the AWS CLI or console, not something Terraform manages here.

**3. Add your domain details** to `infra/variables.tf` (`domain_name` and `subdomain`), and make sure your domain's hosted zone already exists in Route53.

**4. Push to main.** This builds and pushes the image to ECR. Then go to the Actions tab and manually run **Terraform Deploy** to actually roll it out, the health check will fire on its own once that succeeds.

If you'd rather run Terraform locally instead of through the pipeline:

```bash
cd infra
terraform init
terraform plan
terraform apply
```

## Tearing it down

Easiest way is the **Terraform Destroy** workflow in the Actions tab, type "destroy" into the confirmation field it asks for and run it. Or do it locally:

```bash
cd infra
terraform destroy
```

This leaves the S3 state bucket and ECR repo alone since those are meant to be reused. The ALB and NAT Gateway both cost money by the hour, so don't leave this running if you're not using it.

## Proof of application working

URL used: `tm.yasirmoosa.tech`

![Threat Composer running](images/threat-composer-app.png)

## Successful Pipeline Runs

### Docker Image Publish
![Build and Push Image](images/pipeline1-success.png)

### Terraform Plan + Apply
![Terraform Deploy](images/pipeline2-success.png)

### Terraform Plan + Destroy
![Terraform Destroy](images/pipeline3-success.png)

### Domain URL Health Check
![Post-Deployment Health Check](images/pipeline4-success.png)

## CloudWatch Dashboard

![CloudWatch dashboard](images/cloudwatch-dashboard.png)

## Notes on some of the design choices

- The ALB has a `create_before_destroy` lifecycle rule on its target group. Without it, changing certain settings forces a replace and Terraform tries to delete the old target group while a listener still points at it, which fails.
- The ECS task execution role is created by Terraform rather than assumed to already exist, so the whole thing is reproducible in a fresh AWS account.
- The GitHub Actions IAM role currently has broad managed policies attached (EC2, ECS, S3, IAM, Route53, ACM, CloudWatch) rather than a tightly scoped custom policy. For a real production setup this should be narrowed down to only what's actually needed, this was a deliberate shortcut for a learning project, not something I'd do for a client.
- The Docker image's runner stage runs `apk upgrade` (briefly as root, then drops back to the unprivileged `nginx` user) so the base Alpine image's OS packages get security patches at build time rather than shipping whatever was frozen into the base image when it was published.

## License

MIT.
