# EC2 Web Server Deployment — AWS CLI & Apache

A hands-on AWS project demonstrating how to manually deploy and configure an Apache web server on an Amazon EC2 instance using the AWS CLI, covering the full lifecycle from key pair creation to resource cleanup.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Task 1 — Key Pair Generation & Import](#task-1--key-pair-generation--import)
- [Task 2 — EC2 Deployment](#task-2--ec2-deployment)
- [Task 3 — SSH Access Configuration](#task-3--ssh-access-configuration)
- [Task 4 — HTTP Access Configuration](#task-4--http-access-configuration)
- [Task 5 — SSH Connection](#task-5--ssh-connection)
- [Task 6 — User Creation & Permissions](#task-6--user-creation--permissions)
- [Task 7 — Login as acs730](#task-7--login-as-acs730)
- [Task 8 — Apache Web Server Installation](#task-8--apache-web-server-installation)
- [Task 9 — Resource Cleanup](#task-9--resource-cleanup)
- [Key Learnings](#key-learnings)

---

## Overview

This project covers the complete process of launching and configuring a web server on AWS using only the CLI and Linux commands — no console wizards, no automation tools. It demonstrates secure access control, user management, and web server automation using a Bash script.

| Component | Detail |
|---|---|
| Cloud Provider | AWS (us-east-1) |
| Instance Type | t2.micro |
| OS | Amazon Linux 2023 |
| Web Server | Apache (httpd) |
| Access Method | SSH via custom key pair |
| Environment | AWS Cloud9 |

---

## Architecture

```
Internet
    │
    ▼
Security Group (apatel638-sg)
├── Port 22  → SSH (your IP only)
└── Port 80  → HTTP (0.0.0.0/0)
    │
    ▼
EC2 Instance (apatel638-ec2)
├── ec2-user  (default)
└── acs730    (custom user with sudo)
    │
    ▼
Apache Web Server (httpd)
└── /var/www/html/index.html
```

---

## Prerequisites

- AWS account with Cloud9 environment
- AWS CLI configured
- Basic Linux knowledge

---

## Task 1 — Key Pair Generation & Import

Generate a custom SSH key pair in Cloud9 and import the public key into AWS.

```bash
# Generate RSA key pair
ssh-keygen -t rsa -b 2048 -f ~/.ssh/apatel638-key -N ""

# Import public key to AWS
aws ec2 import-key-pair \
  --key-name apatel638-key \
  --public-key-material fileb://~/.ssh/apatel638-key.pub

# Verify the key was imported
aws ec2 describe-key-pairs --key-names apatel638-key
```

![Key pair generated and imported](screenshots/task1-key-import.png)

---

## Task 2 — EC2 Deployment

Launch an EC2 instance using the AWS CLI with the custom key pair and security group.

```bash
# Launch EC2 instance
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --instance-type t2.micro \
  --key-name apatel638-key \
  --security-group-ids <your-sg-id> \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=apatel638-ec2}]'

# Verify instance is running
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=apatel638-ec2" \
  --query "Reservations[0].Instances[0].[InstanceId,PublicIpAddress,State.Name]" \
  --output table
```

![EC2 instance deployed and running](screenshots/task2-ec2-deployed.png)

---

## Task 3 — SSH Access Configuration

Restrict SSH access to your specific IP address only.

```bash
# Allow SSH only from your IP
aws ec2 authorize-security-group-ingress \
  --group-id <your-sg-id> \
  --protocol tcp \
  --port 22 \
  --cidr $(curl -s ifconfig.me)/32
```

![SSH rule configured for specific IP](screenshots/task3-ssh-access.png)

---

## Task 4 — HTTP Access Configuration

Allow HTTP traffic from all sources so the web server is publicly accessible.

```bash
# Allow HTTP from anywhere
aws ec2 authorize-security-group-ingress \
  --group-id <your-sg-id> \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
```

Both SSH (port 22) and HTTP (port 80) rules confirmed active in the AWS Management Console.

![SSH and HTTP rules configured](screenshots/task4-http-access.png)

---

## Task 5 — SSH Connection

Connect to the EC2 instance using the custom private key.

```bash
# Set correct permissions on private key
chmod 400 ~/.ssh/apatel638-key

# Connect to instance
ssh -i ~/.ssh/apatel638-key ec2-user@<public-ip>
```

![SSH connection established as ec2-user](screenshots/task5-ssh-connection.png)

---

## Task 6 — User Creation & Permissions

Create a new Linux user `acs730` with sudo privileges and configure SSH access for the new user.

```bash
# Create user
sudo useradd -m -s /bin/bash acs730

# Grant sudo privileges
echo 'acs730 ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/acs730

# Set up SSH directory and copy authorized keys
sudo mkdir -p /home/acs730/.ssh
sudo cp /home/ec2-user/.ssh/authorized_keys /home/acs730/.ssh/authorized_keys
sudo chown -R acs730:acs730 /home/acs730/.ssh
sudo chmod 700 /home/acs730/.ssh
sudo chmod 600 /home/acs730/.ssh/authorized_keys

# Verify user and sudo privileges
id acs730
sudo -l -U acs730
```

![User acs730 created with sudo access](screenshots/task6-user-creation.png)

---

## Task 7 — Login as acs730

Log in as the new `acs730` user and verify sudo access.

```bash
# Login as acs730
ssh -i ~/.ssh/apatel638-key acs730@<public-ip>

# Verify root-level access
sudo whoami
# Expected output: root
```

![Logged in as acs730 with confirmed sudo](screenshots/task7-login-acs730.png)

---

## Task 8 — Apache Web Server Installation

Automate the installation and configuration of Apache using a Bash script.

### install_httpd.sh

```bash
#!/bin/bash

# Install Apache
sudo yum install -y httpd

# Create custom HTML page
sudo bash -c 'cat > /var/www/html/index.html << HTML
<html>
<head><title>ACS730 Assignment 3</title></head>
<body>
  <h1>Hello from apatel638!</h1>
  <p>ACS730 Assignment 3 - Web Server on Amazon EC2</p>
</body>
</html>
HTML'

# Set ownership
sudo chown acs730:acs730 /var/www/html/index.html

# Start and enable Apache
sudo systemctl start httpd
sudo systemctl enable httpd

echo "Apache installed and running"
```

### Run the script

```bash
chmod +x install_httpd.sh
./install_httpd.sh
```

### Verify the web server

```bash
# Test locally
curl http://localhost

# Test externally (from Cloud9)
curl http://<public-ip>

# Check service status
sudo systemctl status httpd
```

![Apache installed and serving custom HTML](screenshots/task8-apache-running.png)
![Web server verified via public IP](screenshots/task8-external-access.png)
![Apache service status active and running](screenshots/task8-service-status.png)

---

## Task 9 — Resource Cleanup

Terminate the EC2 instance to avoid unnecessary charges.

```bash
# Get instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=apatel638-ec2" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

# Terminate instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Verify termination
aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text
```

> **Always terminate instances after testing.** EC2 instances accrue charges by the hour — even when idle.

![EC2 instance terminated](screenshots/task9-cleanup.png)

---

## Key Learnings

- Generating and importing custom SSH key pairs for secure EC2 access
- Launching and verifying EC2 instances entirely via AWS CLI
- Configuring layered security group rules (IP-restricted SSH, open HTTP)
- Linux user management — creating users, assigning sudo privileges, configuring SSH keys
- Automating web server setup with a Bash script
- Full instance lifecycle management from launch to termination
