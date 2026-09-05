# 生産管理サブシステム（MINERVA-PP）構成

生産計画の立案から製造実績の収集までを担う。主管は製造本部 生産管理部。

## 1. 機能構成図

```mermaid
flowchart TB
    subgraph pp["MINERVA-PP"]
        psi["PSI 計画<br/>(月次・週次)"]
        mrp["所要量展開<br/>(MRP)"]
        wo["製造指図"]
        sched["小日程計画<br/>(スケジューラ)"]
        result["実績収集"]
        cost["原価計算<br/>(月次)"]
    end

    subgraph plant["工場 (八千代・浜松)"]
        mes["MES"]
        handy["現場ハンディ"]
        machine["設備 (PLC)"]
    end

    subgraph rel["社内連携"]
        sd["MINERVA-SD<br/>受注情報"]
        mm["MINERVA-MM<br/>在庫・発注"]
        fi["MINERVA-FI<br/>会計連携"]
        mdm["マスタ管理<br/>(BOM・工程)"]
    end

    sd -->|"受注・内示"| psi
    psi --> mrp
    mdm -.->|"BOM 展開"| mrp
    mrp -->|"購買要求"| mm
    mrp --> wo --> sched
    sched -->|"作業指示"| mes
    mes --> machine
    handy -->|"実績報告"| mes
    mes -->|"作業実績<br/>(15分間隔)"| result
    result -->|"仕掛・完成イベント"| mm
    result --> cost -->|"原価仕訳"| fi

    classDef main fill:#1e6bb8,color:#fff
    classDef plantStyle fill:#e65100,color:#fff
    classDef ext fill:#f5f5f5,stroke:#999,stroke-dasharray: 5 5
    class psi,mrp,wo,sched,result,cost main
    class mes,handy,machine plantStyle
    class sd,mm,fi,mdm ext
```

## 2. 計画サイクル

| 計画 | サイクル | 対象期間 | 確定タイミング |
| --- | --- | --- | --- |
| PSI 計画 | 月次 | 3 ヶ月先まで | 毎月 25 日の需給会議 |
| 週次計画 | 週次 | 2 週間先まで | 毎週木曜 15:00 |
| 小日程計画 | 日次 | 翌 2 営業日 | 前日 17:00 |

## 3. MES 連携の要点

- 作業実績は MES から **15 分間隔** でファイル連携（並行稼働中の暫定方式。API 化は Phase 2）
- 連携断が 1 時間を超えた場合、完成計上が遅延し出荷引当に影響するため **P2 障害** として扱う
- 設備からの自動実績（PLC 経由）と手入力実績（ハンディ）は入力区分で区別し、原価集計では同一に扱う

> 💡 八千代工場は 2 直、浜松工場は昼勤のみ。夜間バッチの実行時間帯設計では八千代の 2 直目（〜23:00）の実績連携を考慮すること。
