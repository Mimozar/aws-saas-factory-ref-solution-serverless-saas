#!/bin/bash -e

export CDK_PARAM_SYSTEM_ADMIN_EMAIL="$1"

if [[ -z "$CDK_PARAM_SYSTEM_ADMIN_EMAIL" ]]; then
  echo "Please provide system admin email"
  exit 1
fi

export REGION=$(aws configure get region)
export CDK_PARAM_CODE_COMMIT_REPOSITORY_NAME="aws-saas-factory-ref-solution-serverless-saas"
if ! aws codecommit get-repository --repository-name $CDK_PARAM_CODE_COMMIT_REPOSITORY_NAME; then
  CREATE_REPO=$(aws codecommit create-repository --repository-name $CDK_PARAM_CODE_COMMIT_REPOSITORY_NAME --repository-description "Serverless saas reference architecture repository")
  echo "$CREATE_REPO"
fi

REPO_URL="codecommit::${REGION}://$CDK_PARAM_CODE_COMMIT_REPOSITORY_NAME"
if ! git remote add cc "$REPO_URL"; then
  echo "Setting url to remote cc"
  git remote set-url cc "$REPO_URL"
fi
git push cc "$(git branch --show-current)":main -f --no-verify
export CDK_PARAM_COMMIT_ID=$(git log --format="%H" -n 1)

# Preprovision pooled infrastructure
cd ../server/cdk
npm install

npx -y cdk bootstrap
npx -y cdk deploy --all --require-approval never --concurrency 10 --asset-parallelism true

echo "Installing client applications, please wait...."
sleep 60

# Deploy client UIs
export CDK_PARAM_REG_API_GATEWAY_URL=$(aws cloudformation describe-stacks --stack-name ControlPlaneStack --query "Stacks[0].Outputs[?OutputKey=='controlPlaneAPIEndpoint'].OutputValue" --output text)
export CDK_COGNITO_ADMIN_USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name ControlPlaneStack --query "Stacks[0].Outputs[?contains(OutputKey,'ControlPlaneIdpUserPoolId')].OutputValue" --output text)
export CDK_COGNITO_ADMIN_CLIENT_ID=$(aws cloudformation describe-stacks --stack-name ControlPlaneStack --query "Stacks[0].Outputs[?contains(OutputKey,'ControlPlaneIdpClientId')].OutputValue" --output text)

cd ../../client/client-template
npm install
npx -y cdk deploy --require-approval never

# Get client URLs
ADMIN_SITE_URL=$(aws cloudformation describe-stacks --stack-name ClientTemplateStack --query "Stacks[0].Outputs[?OutputKey=='adminSiteUrl'].OutputValue" --output text)
APP_SITE_URL=$(aws cloudformation describe-stacks --stack-name ClientTemplateStack --query "Stacks[0].Outputs[?OutputKey=='appSiteUrl'].OutputValue" --output text)
echo "Admin site url: $ADMIN_SITE_URL"
echo "Application site url: https://$APP_SITE_URL"
