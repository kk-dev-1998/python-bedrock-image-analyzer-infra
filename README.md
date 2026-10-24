# python-bedrock-image-analyzer-infra

Terraform-managed AWS infrastructure for [python-bedrock-image-analyzer](https://github.com/kk-dev-1998/python-bedrock-image-analyzer).

[python-bedrock-image-analyzer](https://github.com/kk-dev-1998/python-bedrock-image-analyzer) のAWSインフラをTerraformで管理するリポジトリです。

## Architecture

```
Client → API Gateway (HTTP API) → Lambda (container image, FastAPI)
                                       ├→ S3 (image uploads)
                                       └→ Amazon Bedrock (JP CRIS, Claude Haiku 4.5)
```

Currently, images are uploaded directly to `POST /analyze` as multipart/form-data.
S3-based presigned URL upload is designed and IAM permissions are already in place, but the implementation is planned for a future update (see "Future Work" below).

現在、画像は`POST /analyze`にmultipart/form-dataで直接アップロードする方式で動作しています。
S3経由のpresigned URLアップロード方式は設計・IAM権限のみ用意済みで、実装は今後対応予定です（下記「Future Work」参照）。

## Tech Stack

- Terraform 1.10+ (required for S3 native state locking) / AWS Provider ~> 5.0
- AWS Lambda (container image) / API Gateway (HTTP API) / ECR / S3 / Amazon Bedrock
- tfstate management: S3 (native locking)

## Directory Structure

```
terraform/
├── backend-bootstrap/   # Creates the S3 bucket for tfstate (local state, run once)
├── modules/
│   ├── ecr/              # ECR repository for the Lambda container image
│   ├── iam/               # Lambda execution role (least privilege: Bedrock JP inference profile + S3)
│   ├── lambda/             # Lambda function (container image)
│   ├── apigateway/         # HTTP API (API Gateway v2) + Lambda proxy integration
│   ├── s3/                 # S3 bucket for image uploads (private, encrypted, auto-expiring)
│   └── github-oidc/        # OIDC provider + IAM role for GitHub Actions (no long-lived AWS keys)
├── environments/
│   └── dev/                # Deployment environment (designed for multi-env via tfvars; only dev is actually built)
├── .github/
│   └── workflows/          # CI: terraform fmt / plan / apply via OIDC
└── docs/
    └── adr/                 # Architecture Decision Records
```

Each AWS service has its own module (single responsibility), so components can be swapped or reused independently — e.g. Lambda could later be replaced with ECS without touching IAM or S3.

サービス単位でモジュールを分割しています（単一責任）。Lambda→ECSへの差し替えなど、IAM/S3に触れずに一部だけ入れ替えられる設計です。

## Setup

```bash
# 1. Create the tfstate backend (run once)
cd backend-bootstrap
terraform init && terraform apply

# 2. Create only the ECR repository first (Lambda depends on an existing image)
cd ../environments/dev
terraform init
terraform apply -target=module.ecr

# 3. Build and push the Docker image to ECR
#    (run from the python-bedrock-image-analyzer repo)
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com
docker build --platform linux/amd64 -t image-analysis-api .
docker tag image-analysis-api:latest <ecr-repository-url>:latest
docker push <ecr-repository-url>:latest

# 4. Deploy the rest (Lambda / API Gateway / IAM / S3)
terraform apply
```

Step 2 exists to break a chicken-and-egg problem — Lambda's Terraform config requires an existing ECR image, so the ECR repository must be created (and an image pushed) before the rest of the stack.

手順2は鶏卵問題の回避のためです。LambdaはECR上に既にイメージが存在することを前提とするため、先にECRリポジトリだけを作り、イメージをpushしてから残りを構築します。

## Design Decisions

- **tfstate locking**: Originally designed with a DynamoDB lock table, later migrated to Terraform 1.10's native S3 locking (`use_lockfile`), removing the DynamoDB dependency entirely.

  当初DynamoDBロックで設計しましたが、Terraform 1.10のS3ネイティブロック（`use_lockfile`）へ移行し、DynamoDBを不要にしました。

- **Least-privilege IAM**: Bedrock access is scoped to the JP regional inference profile (CRIS) ARN only; S3 access is scoped to the specific bucket.

  IAMは最小権限で設計しています。BedrockはJPリージョナル推論プロファイル（CRIS）のARNに限定し、S3も対象バケットのみに限定しています。

- **ECR tag mutability**: Set to `MUTABLE` with a `latest` tag for simplicity, given the solo/portfolio scale of this project. In a team or production setting, `IMMUTABLE` tags with commit-hash-based versioning would be preferable for deployment traceability.

  ECRのイメージタグは個人開発規模のため`MUTABLE`+`latest`固定で簡略化しています。チーム開発・本番運用であれば、デプロイの追跡可能性のため`IMMUTABLE`＋コミットハッシュタグが望ましいです。

- **No account ID in source-controlled files**: `terraform.tfvars` never contains the AWS account ID. It's resolved at runtime via `data "aws_caller_identity"` and `module.ecr.repository_url`, so nothing sensitive ends up in the Git history.

  `terraform.tfvars`にAWSアカウントIDを直書きしていません。`data "aws_caller_identity"`と`module.ecr.repository_url`を使い、実行時に自動解決する設計にすることで、Gitの履歴に機微な情報が残らないようにしています。

- **CI/CD via OIDC, not long-lived keys**: GitHub Actions assumes an AWS IAM role via OIDC (short-lived credentials per run) instead of storing AWS access keys as GitHub Secrets. The trust policy is scoped by the `repository` claim (an exact match), rather than the `sub` claim wildcard pattern commonly shown in tutorials — GitHub started embedding numeric owner/repo IDs into `sub` in late 2024, which breaks simple wildcard patterns.

  GitHub ActionsはAWSアクセスキーをSecretsに保存せず、OIDC経由で短命な一時クレデンシャルを都度発行する方式にしています。信頼ポリシーは、チュートリアルでよく見る`sub`クレームのワイルドカードパターンではなく、`repository`クレーム（完全一致）でスコープしています。GitHubが2024年後半以降、`sub`にオーナー/リポジトリの数値IDを埋め込むようになり、単純なワイルドカードパターンでは意図通りに一致しなくなったためです。

- Lambda vs ECS/App Runner comparison: see [ADR 0001](docs/adr/0001-lambda-vs-ecs-vs-apprunner.md)

  Lambda vs ECS/App Runnerの比較検討は[ADR 0001](docs/adr/0001-lambda-vs-ecs-vs-apprunner.md)を参照

## CI/CD

GitHub Actions (`.github/workflows/terraform.yml`) runs on every pull request and on push to `main`.

- **Pull request**: `tflint` + `checkov` run first; `terraform fmt -check` + `terraform plan` follow, with the plan output posted as a PR comment.
- **Push to `main`**: after `tflint` and `checkov` pass, `terraform apply` runs automatically.
- **checkov exceptions**: findings that are intentionally accepted are skipped with an inline `#checkov:skip=<ID>:<reason>` comment on the resource, so every exception and its reason is visible in the code.

Authentication uses OIDC — no AWS access keys are stored in GitHub. The GitHub Actions IAM role (`modules/github-oidc`) has minimal permissions scoped to this project's specific resources (by service, further scoped by resource ARN prefix), not full account access.

GitHub ActionsはPRごと、および`main`へのpush時に実行されます。

- **プルリクエスト時**：`tflint`と`checkov`を実行したうえで、`terraform fmt -check` + `terraform plan`を実行し、結果をPRにコメントとして投稿
- **`main`へのpush時**：`tflint`と`checkov`が通った後に`terraform apply`を自動実行
- **checkovの例外**：意図的に許容する指摘は、対象リソースに`#checkov:skip=<ID>:<理由>`のコメントを付けてスキップしています。例外とその理由はコード上で確認できます。

認証はOIDCを使用しており、GitHub上にAWSアクセスキーを一切保存していません。GitHub Actions用のIAMロール（`modules/github-oidc`）は、アカウント全体への権限ではなく、本プロジェクトの対象リソースに限定した最小権限で構成しています。

## Future Work

- Implement S3 presigned URL upload flow (IAM permissions and CORS are already in place)
  S3経由のpresigned URLアップロード方式の実装（IAM権限・CORS設定は用意済み）  