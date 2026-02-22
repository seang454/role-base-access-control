- This is a Kubernetes RBAC (Role-Based Access Control) setup script that creates a new user with limited permissions. 
# Here's what it does step-by-step:
# Overview
    - The script automates creating a restricted Kubernetes user who can only read pods in a specific namespace. This is useful for labs, training, or giving limited access to team members.
# What Each Section Does
- Initial Setup (Lines 1-13)

Prompts you to enter: username, group name, and namespace
Creates a directory to store certificates: ~/kube-users/$USER
Gets your current Kubernetes cluster name

1️⃣ Create Namespace

Creates a new Kubernetes namespace where the user will have access

2️⃣ Create Role

Defines what permissions exist in that namespace
This role (pod-reader) allows: viewing, listing, and watching pods only
No permissions to create, delete, or modify pods

3️⃣ Create/Update RoleBinding

Binds the Role to the GROUP (not directly to the user)
This means anyone in that group gets the pod-reader permissions
Smart: checks if RoleBinding exists and patches it instead of overwriting

4️⃣ Generate Certificate

Creates a client certificate for the user using OpenSSL
The certificate includes the username (CN) and group (O)
Signed by your Kubernetes cluster's CA (Certificate Authority)
This is how Kubernetes will authenticate the user

5️⃣ Generate Kubeconfig

Creates a personal kubeconfig file for the user
This file contains:

Cluster connection info (API server address)
User credentials (the certificate just created)
Default namespace context


Embeds certificates directly in the file for portability

6️⃣ Output Instructions

Prints test commands to verify the setup
Shows where the kubeconfig file is saved