# Hands-on RBAC Lab
- Create a namespace
- Create a ServiceAccount
- Create a Role (read-only pods)
- Bind the Role
- Test access (allowed & denied)\

- testing: kubectl auth can-i : Test RBAC permissions (IMPORTANT PART)
        - Basic syntax
            -kubectl auth can-i <verb> <resource>
        -  kubectl auth can-i is used to check permissions — basically to answer:
            - “Am I (or this user/service account) allowed to do X on Y in Kubernetes?”
```bash
kubectl auth can-i list pods \
  --as=system:serviceaccount:rbac-test:test-sa \
  -n rbac-test
```
```bash kubctl auth can-i <verb> <resource> \
    --as=system:<Subjects>:<namespace>:<subjectname> -n <namespace>
```

output yes mean : it can access 

```bash
kubectl auth can-i create pods \
  --as=system:serviceaccount:rbac-test:test-sa \
  -n rbac-test
```
output 


# Adding real World testing
1. Create a Pod using this ServiceAccount
```bash
apiVersion: v1
kind: Pod
metadata:
  name: rbac-demo-pod
  namespace: rbac-test
spec:
  serviceAccountName: test-sa
  containers:
  - name: kubectl
    image: bitnami/kubectl
    command: ["sleep", "3600"]
```
- then : kubectl apply -f pod.yaml

2. Exec into the Pod
- command : kubectl exec -it rbac-demo-pod -n rbac-test -- sh
3. Step 7️⃣ Test allowed action ✅
- command kubectl get pods -n rbac-test
-   Works — because list pods is allowed.
4. Test forbidden action ❌
- command : kubectl run test --image=nginx -n rbac-test
- Expected error: Error from server (Forbidden): pods is forbidden

- What just happened internally of this example?
    - Pod uses ServiceAccount token (auto-mounted)
    - API Server authenticates: `system:serviceaccount:rbac-test:test-sa`
    - RBAC (Role base access control) checks:
        - Example : 
            - list pods → ✅ allowed
            - create pods → ❌ denied
- Mental model (remember this)
```bash 
Pod
 ↓
ServiceAccount
 ↓
Role / ClusterRole
 ↓
Allowed or Forbidden

```

# How a Pod authenticates to Kubernetes API
- When a Pod uses a ServiceAccount, Kubernetes automatically injects credentials into the Pod
    - These are mounted here : `/var/run/secrets/kubernetes.io/serviceaccount/ (path on pod "mouted from kubernet to here")`
    - testing:
        - kubectl exec -it rbac-demo-pod -n rbac-test -- sh
        - ls /var/run/secrets/kubernetes.io/serviceaccount/
            - you will see :  ca.crt, namespace, token
                - File	            - Purpose
                - token	            - JWT token for authentication
                - ca.crt	        - Cluster CA certificate
                - namespace	        - Pod’s namespace
            - This token represents: system:serviceaccount:rbac-test:test-sa
                - THIS is the identity RBAC checks.

- Use the token to call Kubernetes API manually (mind-blowing 🤯)
    ```bash
        TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
        curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
        -H "Authorization: Bearer $TOKEN" \
        https://kubernetes.default.svc/api/v1/namespaces/rbac-test/pods
    ```
    - same as : kubectl get pods -n rbac-test
    ```bash
        curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
        -H "Authorization: Bearer $TOKEN" \
        https://kubernetes.default.svc/api/v1/namespaces/rbac-test/pods \
        -X POST
    ```
    - CREATE a Pod in the rbac-test namespace
    - this will "forbidden"

```bash
Pod
 ↓ (token mounted)
ServiceAccount
 ↓ (JWT identity)
API Server
 ↓ (RBAC check)
Allow / Deny
```

# 🏗️ ClusterRole vs Role

| Feature   | Role                                                  | ClusterRole                                                                   |
|-----------|-------------------------------------------------------|-------------------------------------------------------------------------------|
| Scope     | Single namespace                                      | Whole cluster (all namespaces)                                                |
| Use case  | Grant permissions for namespace-specific resources    | Grant global permissions, or resources not tied to a namespace (e.g., nodes)  |
| Binding   | RoleBinding                                           | ClusterRoleBinding (or RoleBinding in a namespace)                            |
| Examples  | Read pods in `dev` namespace                          | List all nodes, cluster-wide admin, read all pods in all namespaces           |


# role-base-access-control
