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