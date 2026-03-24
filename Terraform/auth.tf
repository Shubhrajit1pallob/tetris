# Authentication resources have been moved to the dedicated stack:
#   ../auth
#
# This main Terraform stack intentionally excludes Azure AD / OIDC bootstrap
# resources so infra state and auth state are managed separately.
#
# Auth stack usage:
#   terraform -chdir=auth init -backend-config=backend.conf
#   terraform -chdir=auth plan
#   terraform -chdir=auth apply
