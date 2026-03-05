- A ClusterRole in Kubernetes is a set of permissions that can apply cluster-wide, unlike a regular Role which is namespace-scoped. It defines what actions can be performed on which resources, and can be bound to users, groups, or ServiceAccounts.

| Feature  | Role                     | ClusterRole                                      |
| -------- | ------------------------ | ------------------------------------------------ |
| Scope    | One namespace            | All namespaces                                   |
| Binding  | RoleBinding              | ClusterRoleBinding (or RoleBinding to namespace) |
| Example  | Read pods in `dev`       | Read pods in all namespaces                      |
| Use case | App limited to namespace | CI/CD pipelines, admins                          |


- command to run 
```bash
kubectl run test-pod -n rbac-crole --serviceaccount=ci-service --image=bitnami/kubectl -- sleep infinity # running pod (v1.25+ Not longer support , please using pod instead)
kubectl exec -it test-pod -n rbac-crole -- sh
kubectl get pods -n dev        # ✅ allowed
kubectl get pods -n default    # ✅ allowed
kubectl get pods -n kube-system # ✅ allowed

# list the created role in our clusterRole
kubectl get clusterrole -n rbac-crole  | grep pod-reader-all

```
```bash
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: rbac-crole
spec:
  serviceAccountName: ci-service
  containers:
  - name: kubectl
    image: bitnami/kubectl
    command: ["sleep", "3600"]
# command
kubectl apply -f test-pod.yaml
kubectl get pods -n rbac-crole
kubectl exec -it test-pod -n rbac-crole -- sh
```


# Three Types of Subjects in Kubernetes

WHO can authenticate to Kubernetes?

1. User
2. Group
3. ServiceAccount

1. User
```bash
- Represents a HUMAN (like you)
- Kubernetes does NOT manage users
- No token created by K8s
- Uses certificate + private key instead

Example: YOUR ~/.kube/config
  client-certificate-data: LS0tLS1CRUdJTi...  ← certificate
  client-key-data: LS0tLS1CRUdJTiBSU0E...     ← private key

Token needed? ❌ Uses certificate instead

```
2. Group
```bash
- Represents a COLLECTION of users
- Kubernetes does NOT manage groups either
- No token, no certificate
- Just a label to apply roles to many users at once

Example:
  system:masters      ← built-in admin group
  system:authenticated ← all authenticated users
  developers          ← custom group you define

Token needed? ❌ Groups don't authenticate
                 individual users inside group authenticate

```

3. ServiceAccount
```bash
- Represents an APPLICATION (like Jenkins)
- Kubernetes DOES manage service accounts
- Lives inside a namespace
- NEEDS a token to authenticate

Example: jenkins-admin in devops-tools namespace

Token needed? ✅ YES — this is the only one
                       K8s creates/manages tokens for

```

# sum up
|                         | User                | Group        | ServiceAccount  |
|                         |                     |---           |---              |
| **Represents**          | Human       | Collection of users  | Application     |
| **Managed by K8s**      | ❌          | ❌                  | ✅              |
| **Auth method**         | Certificate  | N/A                 | Token            |
| **Needs token**         | ❌          | ❌                  | ✅              |
| **Lives in namespace**  | ❌          | ❌                  | ✅              |
| **Example**             | you          | developers          | jenkins-admin    |