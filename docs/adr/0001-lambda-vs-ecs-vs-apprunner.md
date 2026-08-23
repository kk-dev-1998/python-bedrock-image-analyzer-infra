以下をそのまま`docs/adr/0001-lambda-vs-ecs-vs-apprunner.md`にコピペしてください。

---

# ADR 0001: Compute platform for the image analysis API — Lambda vs ECS Fargate vs App Runner

コンピュートプラットフォームの選定：Lambda vs ECS Fargate vs App Runner

## Status / ステータス

Accepted（2026年8月）

## Context / 背景

**English**: The application is a FastAPI-based image analysis API that receives an image, calls Amazon Bedrock (Claude Haiku 4.5), and returns a JSON result. Traffic is low and unpredictable (demo use, not production with sustained load). Three AWS compute options were considered: AWS Lambda (container image), Amazon ECS on Fargate, and AWS App Runner.

**日本語**：本アプリケーションは、画像を受け取りAmazon Bedrock（Claude Haiku 4.5）を呼び出してJSON結果を返す、FastAPIベースの画像解析APIです。トラフィックは少なく予測不能（本番の持続的負荷ではなく、デモ用途）です。コンピュート選択肢として、AWS Lambda（コンテナイメージ）、Amazon ECS on Fargate、AWS App Runnerの3つを検討しました。

## Decision / 決定

**English**: We chose **AWS Lambda with a container image**, fronted by API Gateway (HTTP API).

**日本語**：**AWS Lambda（コンテナイメージ）**を採用し、API Gateway（HTTP API）でフロントすることを決定しました。

## Comparison / 比較

| | AWS Lambda | ECS Fargate | App Runner |
|---|---|---|---|
| **Cost at near-zero traffic**<br>ほぼゼロトラフィック時のコスト | Pay per request/duration. Scales to zero.<br>リクエスト/実行時間課金。ゼロまでスケール可能 | Requires at least one running task; billed continuously even when idle.<br>最低1タスクを常時起動する必要があり、アイドル時も継続課金 | Minimum instance billing applies even at low traffic (though lower than Fargate).<br>低トラフィックでも最低限のインスタンス課金が発生（Fargateよりは低い） |
| **Operational complexity**<br>運用の複雑さ | No cluster, no load balancer to manage. IaC is a single function + API Gateway.<br>クラスタ・ロードバランサーの管理不要。IaCは関数+API Gatewayのみ | Requires VPC design, ALB, task definitions, cluster/service management.<br>VPC設計、ALB、タスク定義、クラスタ/サービス管理が必要 | Simpler than Fargate (no ALB/cluster to manage), but less mature/flexible than Lambda+API Gateway.<br>Fargateより単純（ALB/クラスタ管理不要）だが、Lambda+API Gatewayより柔軟性・成熟度に劣る |
| **Cold start**<br>コールドスタート | Present, but acceptable for this use case (observed within the 30s Lambda timeout).<br>発生するが、本用途では許容範囲（30秒のLambdaタイムアウト内に収まることを確認済み） | Minimal (long-running containers).<br>ほぼなし（常時起動コンテナのため） | Minimal, but auto-scaling to zero is not supported the way Lambda is.<br>ほぼないが、Lambdaのようなゼロへのスケールインは非対応 |
| **IAM granularity**<br>IAM権限の粒度 | Naturally scoped to a single execution role per function.<br>関数単位で実行ロールが自然に分離される | Requires task role design; still function-equivalent granularity is achievable but with more moving parts.<br>タスクロール設計が必要。同等の粒度は実現可能だが構成要素が増える | Similar to Fargate via instance role.<br>インスタンスロール経由でFargateと同様 |
| **Fit for this project**<br>本プロジェクトへの適合性 | Best fit: bursty/near-zero traffic, single endpoint, portfolio-scale.<br>最適：突発的/ほぼゼロのトラフィック、単一エンドポイント、ポートフォリオ規模 | Overkill for current traffic; better suited to sustained, high-throughput workloads.<br>現在のトラフィックにはオーバースペック。持続的・高スループットなワークロードに向く | A reasonable middle ground, but doesn't outperform Lambda for this specific access pattern.<br>妥当な中間案だが、本アクセスパターンにおいてLambdaを上回る利点はない |

## Consequences / 影響

**English**:
- Positive: near-zero idle cost, minimal infrastructure to maintain (no VPC/ALB/cluster), IAM policy stays scoped to a single function.
- Negative: cold starts on the first request after idle periods; the 10GB container image size limit and 15-minute max execution time would become constraints if the application grows significantly (e.g., long-running batch processing).
- If sustained, high-throughput production traffic becomes a real requirement in the future, ECS Fargate (or App Runner as a lighter-weight alternative) should be reconsidered.

**日本語**：
- ポジティブな影響：アイドル時のコストがほぼゼロ、維持すべきインフラが最小限（VPC/ALB/クラスタ不要）、IAMポリシーが単一関数に自然にスコープされる
- ネガティブな影響：アイドル後の初回リクエストでコールドスタートが発生する。コンテナイメージサイズの上限（10GB）や最大実行時間（15分）は、アプリケーションが大きく成長した場合（例：長時間のバッチ処理）制約になりうる
- 将来、持続的で高スループットな本番トラフィックが実際に必要になった場合は、ECS Fargate（またはより軽量な代替としてApp Runner）を再検討すべき