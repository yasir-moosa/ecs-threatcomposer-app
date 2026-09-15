# Threat Composer on ECS Fargate

Threat Composer is an open source app from AWS that helps you build out threat models, you can have a play with it yourself here: [Threat Composer Tool](https://awslabs.github.io/threat-composer/workspaces/default/dashboard). 

I took it and deployed it the way you'd actually run something like this in a job: containerised, running on ECS Fargate, sitting behind a load balancer with a real HTTPS domain, all built with Terraform and deployed through a CI/CD pipeline with no long lived AWS keys anywhere.

Live at: `https://tm.yasirmoosa.tech`

## What this actually does

Threat Composer runs as a Docker container inside ECS Fargate. Traffic comes in through an Application Load Balancer on port 443, gets terminated with a real ACM certificate and gets routed to whichever Fargate task is healthy at the time. There's no server to patch or SSH into, Fargate handles the compute for you.

Everything from the VPC up is created by Terraform.

## Architecture

- A VPC spanning two Availability Zones with public and private subnets in each
- A NAT Gateway so the Fargate tasks in the private subnets can pull the image from ECR and reach the internet
- An Application Load Balancer in the public subnets (listening on 80 and 443)
- Port 80 just redirects straight to 443 (nothing serves plain HTTP)
- ECS Fargate service running the Threat Composer container in the private subnets
- ECR repository storing the built Docker image
- ACM certificate for `tm.yasirmoosa.tech` which validated automatically through a DNS record in Route53
- Route53 hosted zone and A record pointing the subdomain at the load balancer
- S3 bucket holding the Terraform remote state

*Architecture diagram here*

## Folder layout

```
.
├── app/                        # the app source + Dockerfile
├── bootstrap/
│   ├── s3_backend/              # one-off to creates the S3 bucket for remote state
│   └── ecr_bootstrap/           # one-off to creates the ECR repo
├── infra/
│   ├── main.tf
│   ├── variables.tf
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
        └── health-check.yml
```

## CI/CD

There are three workflows and they're chained, not run manually one after another:

1. **Build and Push Image** runs on a push that touches `app/` or the Dockerfile (or can be triggered manually). It builds the image, tags it with the commit SHA and pushes it to ECR.
2. **Terraform Deploy** runs after that one finishes successfully or on its own if you push a change under `infra/`. It runs `terraform init`, `plan` and `apply` against the real infra.
3. **Post-Deploy Health Check** runs after Terraform Deploy finishes. It curls the live site and fails the pipeline if it doesn't get a healthy response back.

So in practice, a normal code change to the app goes: push to main, image gets built and pushed, infra gets applied (which picks up the new image) then the pipeline checks the site is actually up before calling it done. If any stage fails, the ones after it don't run.

None of this uses long lived AWS access keys. GitHub Actions authenticates to AWS through OIDC: AWS trusts GitHub's identity provider directly and issues short lived credentials to a specific IAM role only when the workflow is running from this exact repo. No secrets to rotate or leak.

## Running this yourself

You'll need an AWS account, the AWS CLI configured, Terraform, Docker and a domain you control in Route53 if you want the HTTPS part to work.

**1. Create the remote state bucket and ECR repo** (one time only)

```bash
cd bootstrap/s3_backend
terraform init && terraform apply

cd ../ecr_bootstrap
terraform init && terraform apply
```

**2. Set up the OIDC identity provider and IAM role in AWS** so GitHub Actions can deploy without static keys. This is a one time manual step done through the AWS CLI or console, not something Terraform manages here.

**3. Add your domain details** to `infra/variables.tf` (`domain_name` and `subdomain`) and make sure your domain's hosted zone already exists in Route53.

**4. Push to main.** The pipeline takes it from there: builds the image, deploys the infra, checks it's healthy.

If you'd rather run Terraform locally instead of through the pipeline:

```bash
cd infra
terraform init
terraform plan
terraform apply
```

## Tearing it down

```bash
cd infra
terraform destroy
```

This leaves the S3 state bucket and ECR repo alone since those are meant to be reused. The ALB and NAT Gateway both cost money by the hour so don't leave this running if you're not using it.

## Screenshots

*Screenshot of the site over HTTPS here*

*Screenshot of a successful pipeline run here*

## Notes on some of the design choices

- The ALB has a `create_before_destroy` lifecycle rule on its target group. Without it, changing certain settings forces a replace and Terraform tries to delete the old target group while a listener still points at it, which fails.
- The ECS task execution role is created by Terraform rather than assumed to already exist so the whole thing is reproducible in a fresh AWS account.
- The GitHub Actions IAM role currently has broad managed policies attached (EC2, ECS, S3, IAM, Route53, ACM, CloudWatch) rather than a tightly scoped custom policy. For a real production setup this should be narrowed down to only what's actually needed, this was a deliberate shortcut for a learning project, not something I'd do for a client.

## License

MIT.
