#!/bin/bash -xe

export CDK_PARAM_CONTROL_PLANE_SOURCE='sbt-control-plane-api'
export CDK_PARAM_ONBOARDING_DETAIL_TYPE='Onboarding'
export CDK_PARAM_PROVISIONING_DETAIL_TYPE=$CDK_PARAM_ONBOARDING_DETAIL_TYPE
export CDK_PARAM_APPLICATION_NAME_PLANE_SOURCE="sbt-application-plane-api"
export CDK_PARAM_OFFBOARDING_DETAIL_TYPE='Offboarding'
export CDK_PARAM_DEPROVISIONING_DETAIL_TYPE=$CDK_PARAM_OFFBOARDING_DETAIL_TYPE
export CDK_PARAM_PROVISIONING_EVENT_SOURCE="sbt-application-plane-api"
export CDK_PARAM_CODE_COMMIT_REPOSITORY_NAME="aws-saas-factory-ref-solution-serverless-saas"
export CDK_PARAM_LAMBDA_CANARY_DEPLOYMENT_PREFERENCE="true"
export CDK_PARAM_COMMIT_ID=$CODE_COMMIT_ID
echo "CDK_PARAM_COMMIT_ID: $CDK_PARAM_COMMIT_ID"
export CDK_PARAM_SYSTEM_ADMIN_EMAIL="EMAIL"
echo "Update stack: $STACK_NAME"
export CDK_PARAM_TENANT_ID=$TENANT_ID
echo "TenantId: $CDK_PARAM_TENANT_ID"

cd server/cdk
npm install

npx cdk deploy "$STACK_NAME" --exclusively --require-approval never
