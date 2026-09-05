# AWS インフラ構成図

MINERVA 本番環境（PROD）の AWS 構成。DEV / STG との差分は「技術スタック・環境一覧」を参照。

## 1. ネットワーク・コンピュート構成

```mermaid
flowchart TB
    users["社内利用者"] -->|"Direct Connect /<br/>Client VPN"| tgw["Transit Gateway"]

    subgraph vpc["VPC minerva-prod (10.20.0.0/16)"]
        subgraph pub["Public Subnet"]
            nat["NAT Gateway"]
        end
        subgraph priv1["Private Subnet (アプリ層)"]
            alb["内部 ALB"]
            subgraph ecs["ECS Fargate クラスタ"]
                svc1["sd-service ×4"]
                svc2["pp-service ×4"]
                svc3["mm-service ×2"]
                svc4["fi-service ×2"]
                svc5["portal / api-gateway ×2"]
            end
        end
        subgraph priv2["Private Subnet (データ層)"]
            aurora[("Aurora PostgreSQL<br/>Multi-AZ")]
            mq["Amazon MQ<br/>(冗長構成)"]
            redis[("ElastiCache<br/>セッション")]
        end
    end

    subgraph mgmt["共通アカウント"]
        cw["CloudWatch<br/>監視・SLO"]
        s3[("S3<br/>連携ファイル・バックアップ")]
        sm["Secrets Manager"]
    end

    tgw --> alb --> svc5 --> svc1 & svc2 & svc3 & svc4
    svc1 & svc2 & svc3 & svc4 --> aurora
    svc1 & svc2 & svc3 & svc4 -.-> mq
    svc5 --> redis
    ecs -.->|"外部 SaaS 通信"| nat
    ecs -.-> sm
    aurora -.-> s3
    ecs -.->|"ログ・メトリクス"| cw

    classDef compute fill:#1e6bb8,color:#fff
    classDef data fill:#2e7d32,color:#fff
    classDef net fill:#6a1b9a,color:#fff
    class svc1,svc2,svc3,svc4,svc5 compute
    class aurora,mq,redis,s3 data
    class tgw,alb,nat net
```

## 2. アカウント分離

| AWS アカウント | 用途 |
| --- | --- |
| minato-minerva-prod | 本番ワークロード |
| minato-minerva-stg | STG / DEV |
| minato-shared | 監視・ログ集約・CI/CD ランナー |
| minato-security | CloudTrail / Config / GuardDuty 集約 |

## 3. 運用上のポイント

- ECS タスク数は業務時間（7:30〜21:00）とそれ以外で Auto Scaling の下限を切替
- Aurora のフェイルオーバー試験は **半期に 1 回**、DR（別リージョン復旧）訓練は年 2 回
- 連携ファイル（EDI・MES・FB）はすべて S3 経由とし、SFTP サーバは持たない（AWS Transfer Family を利用）

> 💡 セキュリティグループの変更は Terraform 経由のみ。コンソールでの手変更は毎朝の drift 検知で検出され、#sys-minerva-infra に通知される。
