#!/bin/bash
set -e

echo "--------------------------------"
echo "Existing Namespaces, RoleBindings, Subjects, and Roles:"
echo "--------------------------------"

kubectl get rolebindings -A -o json | jq -r '
  .items
  | sort_by(.metadata.namespace)
  | group_by(.metadata.namespace)[] 
  | .[0].metadata.namespace as $ns
  | "Namespace: \($ns)\n--------------------",
    ( .[] |
        .metadata.name as $rb |
        .roleRef.name as $role |
        (.subjects[]? | "  RoleBinding: \($rb) → \(.kind):\(.name) → Role: \($role)")
    ),
    ""
'

echo "--------------------------------"

# -----------------------------
# Interactive input
# -----------------------------
echo "Enter new RBAC user details:"
read -p "USER name: " USER
read -p "GROUP name: " GROUP
read -p "NAMESPACE: " NAMESPACE

CERT_DIR=~/kube-users/$USER
mkdir -p $CERT_DIR

KUBECONFIG_USER=$CERT_DIR/$USER.kubeconfig
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.contexts[0].context.cluster}')

echo "--------------------------------"
echo "You entered:"
echo "  USER      = $USER"
echo "  GROUP     = $GROUP"
echo "  NAMESPACE = $NAMESPACE"
echo

# -----------------------------
# 1️⃣ Create namespace
# -----------------------------
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
EOF

# -----------------------------
# 2️⃣ Create Role
# -----------------------------
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: $NAMESPACE
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
EOF

# -----------------------------
# 3️⃣ Create or update RoleBinding for group
# -----------------------------
RB_NAME="pod-reader-binding-$GROUP"

# If RoleBinding exists, patch to add group (avoids overwriting)
if kubectl get rolebinding "$RB_NAME" -n "$NAMESPACE" &>/dev/null; then
  echo "RoleBinding $RB_NAME already exists, ensuring $GROUP is added..."
  kubectl patch rolebinding "$RB_NAME" -n "$NAMESPACE" \
    --type=json \
    -p "[{\"op\":\"add\",\"path\":\"/subjects/-\",\"value\":{\"kind\":\"Group\",\"name\":\"$GROUP\",\"apiGroup\":\"rbac.authorization.k8s.io\"}}]" || true
else
  echo "Creating RoleBinding $RB_NAME..."
  kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $RB_NAME
  namespace: $NAMESPACE
subjects:
- kind: Group
  name: $GROUP
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF
fi

# -----------------------------
# 4️⃣ Generate certificate
# -----------------------------
echo "Generating certificate for $USER..."
openssl genrsa -out $CERT_DIR/$USER.key 2048
openssl req -new -key $CERT_DIR/$USER.key -out $CERT_DIR/$USER.csr -subj "/CN=$USER/O=$GROUP"
openssl x509 -req -in $CERT_DIR/$USER.csr \
  -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key \
  -CAcreateserial -out $CERT_DIR/$USER.crt \
  -days 365

# -----------------------------
# 5️⃣ Generate kubeconfig
# -----------------------------
APISERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA_CERT=$CERT_DIR/ca.crt
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 --decode > $CA_CERT

kubectl config --kubeconfig=$KUBECONFIG_USER set-cluster $CLUSTER_NAME \
  --server=$APISERVER \
  --certificate-authority=$CA_CERT \
  --embed-certs=true

kubectl config --kubeconfig=$KUBECONFIG_USER set-credentials $USER \
  --client-certificate=$CERT_DIR/$USER.crt \
  --client-key=$CERT_DIR/$USER.key \
  --embed-certs=true

kubectl config --kubeconfig=$KUBECONFIG_USER set-context $USER-context \
  --cluster=$CLUSTER_NAME \
  --user=$USER \
  --namespace=$NAMESPACE

kubectl config use-context $USER-context --kubeconfig=$KUBECONFIG_USER

# -----------------------------
# 6️⃣ Output instructions
# -----------------------------
echo
echo "✅ RBAC Lab setup complete!"
echo "Kubeconfig for user: $KUBECONFIG_USER"
echo
echo "Test commands:"
echo "  kubectl --kubeconfig=$KUBECONFIG_USER get pods -n $NAMESPACE"
echo "  kubectl --kubeconfig=$KUBECONFIG_USER run test-pod --image=nginx -n $NAMESPACE"
echo "  kubectl --kubeconfig=$KUBECONFIG_USER get pods -n default"
