---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: kubernetes-ca
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: dev-user-cert
  namespace: rbac-test
spec:
  secretName: dev-user-tls
  duration: 365d
  renewBefore: 30d
  commonName: dev-user         # CN becomes the username
  organization:
    - dev-team                 # O becomes the group
  privateKey:
    algorithm: RSA
    size: 2048
  issuerRef:
    name: kubernetes-ca
    kind: ClusterIssuer
