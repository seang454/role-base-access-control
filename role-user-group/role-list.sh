echo "--------------------------------"
echo "Existing Namespaces, RoleBindings, Subjects and Roles:"
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
