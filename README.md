# python-bedrock-image-analyzer-infra

[python-bedrock-image-analyzer](リンク) のAWSインフラをTerraformで管理するリポジトリ。

## アーキテクチャ

Client → API Gateway (HTTP API) → Lambda (コンテナイメージ, FastAPI)
                                       ├→ S3 (画像アップロード, presigned URL経由)
                                       └→ Amazon Bedrock (JP CRIS, Claude Haiku 4.5)

## 技術スタック

- Terraform 1.7+ / AWS Provider ~> 5.0
- AWS Lambda（コンテナイメージ）/ API Gateway (HTTP API) / S3 / Amazon Bedrock
- tfstate管理：S3 + DynamoDB

## ディレクトリ構成

python-bedrock-image-analyzer-infra/
├── .gitignore
├── README.md
├── backend-bootstrap/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── modules/
│   ├── iam/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── lambda/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── apigateway/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── s3/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    └── dev/
        ├── main.tf
        ├── variables.tf
        ├── backend.tf
        └── terraform.tfvars

## セットアップ

\`\`\`bash
cd backend-bootstrap && terraform init && terraform apply
cd ../environments/dev && terraform init && terraform apply
\`\`\`

## 設計判断

- Lambda vs ECS/App Runnerの比較検討は [ADR](リンク) を参照
- IAMは最小権限（Bedrock推論プロファイル・S3バケットともにARNを限定）
- 画像はpresigned URL経由でクライアントから直接S3へアップロード（Lambdaのペイロードサイズ制限回避）

## CI/CD

GitHub Actions（OIDC認証）で fmt → plan → apply を自動化（[ワークフロー](リンク)）