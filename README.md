# terraform-aws-subspace
Opinionated module for quick Subspace Wireguard VPN deployment on AWS

## Introduction

Infrastructure deployment for [subspacecommunity/subspace](https://github.com/subspacecommunity/subspace)

## Documentation

This project is intended to be a thin layer over the subspace project. The added capabilities are:
- periodic backup to an S3 bucket
- ssh key written to a bucket of choice, so you can later access the EC2 instance via SSH
- Web App, Wireguard endpoint and Internal Alias Route53 Records

### Arguments

Refer to subspace documentation in the aforementioned repository. The module variables map directly to
the subspace configuration variables. The module variables also have descriptions.

### Behaviours

The current behaviour is to always have the IAM image updated. Since we don't use instance resources
directly, but rather delegate to an autoscaling group for launching the VPN Instance, we can reliably update
the IAM image without affecting deployed resources.

A side effect of this is having to redeploy the VPN to update the base IAM image which is used to launch the
EC2 instance.

To update the instance:
- set desired instances to 0
- wait until resources are removed
- set desired instances to 1

Since we don't have high availability implemented at the moment, all updates will incur downtime. This is
necessary because the main instance needs to be able to associate itself to the ElasticIP. This association
dictates which instance is the main instance in an HA scenario. When HA is enabled, a zero downtime update
would be to increase the desired of instances by 1 and progressivelly remove the old instances. Eventually
the main instance will be deleted (which will still cause the web app to be down, but the VPN itself would
still be up), freeing the ElasicIP. The next instance to be launched would successfully associate the ElasticIP
to itself and it will configure itself to behave as the main instance.

#### Main instance

The main instance behaviour is first and foremost to serve the web application.

Secondly it will backup its configurations periodically to an S3 bucket. When launching, if it detects a previous
backup, then it will use the backup to set itself up.

#### Worker instances

The worker instances are those that fail to acquire the ElasticIP. Their job is to pull the backup from S3
periodically and restart the VPN in case they detect changes.

### Utility scripts

Scripts deployed to the main instance `$HOME` folder:

#### update.sh

Run this script to update the subspace image without having to recreate the instance:

```shell
ssh -i ~/.ssh/private-key.pem \
  ec2-user@internal.example.com \
  'sh ~/update.sh'
```

Change the key name and internal endpoint to match your configuration.

####

## High Availability

The plan is to add a network load balancer in front of the EC2 instances launched by the autoscaling group.
In theory everything is set up, but it still needs to be tested whether the HA behaviour described holds up.

## Examples

Examples can be found in the `examples/` folder.

### Pre-requisites

- An AWS Account
- Tag the default VPC and default subnet with `Name = default`
- A correctly configured route53 zone
  - in case you own a domain managed by route53 registrar, just use the same zone
  - in case you own a domain managed by a different registrar (i.e. Cloudflare), you must delegate the zone using delegation sets or zone name servers
