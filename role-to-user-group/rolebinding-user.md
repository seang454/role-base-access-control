# # rolebinding-user.yaml
# apiVersion: rbac.authorization.k8s.io/v1
# kind: RoleBinding
# metadata:
#   name: pod-reader-binding
#   namespace: dev-user-test
# subjects:
# - kind: User
#   name: dev-user
#   apiGroup: rbac.authorization.k8s.io
# roleRef:
#   kind: Role
#   name: pod-reader
#   apiGroup: rbac.authorization.k8s.io
