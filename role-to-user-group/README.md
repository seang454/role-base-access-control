1. Create a namespace
    - kubectl create namespace dev-user-test
2. Create a Role
```bash
# role-user.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev-user-test
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get","list","watch"]

```
3. Create a RoleBinding for the user
```bash
# rolebinding-user.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: dev-user-test
subjects:
- kind: User
  name: dev-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io

```
- dev-user is a human username you will define in your kubeconfig.


4. Generate kubeconfig for the user
    - Since Kubespray manages certificates automatically, you can use the cluster’s admin kubeconfig as a template.

    - Copy the admin kubeconfig:
```bash 
mkdir -p ~/kubeconfigs
cp ~/.kube/config ~/kubeconfigs/admin.conf
```

5. Generate a client certificate using the cluster CA
    - Kubespray stores CA in /etc/kubernetes/pki (on the master nodes). You can generate a cert for dev-user:
```bash
USER=dev-user
CERT_DIR=~/kubeconfigs/$USER
mkdir -p $CERT_DIR

# Create private key
openssl genrsa -out $CERT_DIR/$USER.key 2048

# Create CSR
openssl req -new -key $CERT_DIR/$USER.key -out $CERT_DIR/$USER.csr -subj "/CN=$USER/O=dev-team"

# Sign CSR with Kubespray CA
openssl x509 -req -in $CERT_DIR/$USER.csr \
  -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key \
  -CAcreateserial -out $CERT_DIR/$USER.crt -days 365

```

Now you have:

$CERT_DIR/$USER.crt
$CERT_DIR/$USER.key

6. Create kubeconfig for the user
```bash
kubectl config set-cluster kubernetes \
  --server=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}') \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true \
  --kubeconfig=$CERT_DIR/$USER.kubeconfig

kubectl config set-credentials $USER \
  --client-certificate=$CERT_DIR/$USER.crt \
  --client-key=$CERT_DIR/$USER.key \
  --embed-certs=true \
  --kubeconfig=$CERT_DIR/$USER.kubeconfig

kubectl config set-context $USER-context \
  --cluster=kubernetes \
  --user=$USER \
  --namespace=dev-user-test \
  --kubeconfig=$CERT_DIR/$USER.kubeconfig

kubectl config use-context $USER-context --kubeconfig=$CERT_DIR/$USER.kubeconfig

```

✅ Now $USER.kubeconfig can be used by dev-user to test RBAC.

Step 6: Test RBAC as dev-user
```bash
kubectl --kubeconfig=~/kubeconfigs/dev-user/dev-user.kubeconfig get pods -n dev-user-test
# Try forbidden actions
kubectl --kubeconfig=~/kubeconfigs/dev-user/dev-user.kubeconfig run test-pod --image=nginx -n dev-user-test
```
Allowed → if Role permits

Forbidden → if Role denies


<!-- 4. Configure kubeconfig for the user
- If your cluster uses kubeconfig + client certificates:
    1. Generate a certificate for dev-user (or token via OIDC).
    2. Add a user entry in kubeconfig:
```bash
users:
- name: dev-user
  user:
    client-certificate: /path/to/dev-user.crt
    client-key: /path/to/dev-user.key
```
    3. Add a context:
```bash
contexts:
- name: dev-user-context
  context:
    cluster: kubernetes
    user: dev-user
    namespace: dev-user-test
```
    4. Switch context:
```bash
kubectl config use-context dev-user-context
```
5. Step 5: Test RBAC for the user
```bash
# Allowed
kubectl get pods -n dev-user-test
kubectl watch pods -n dev-user-test

# Forbidden
kubectl create pod test-pod --image=nginx -n dev-user-test
kubectl get pods -n default

``` -->