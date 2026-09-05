# 在庫・購買管理サブシステム（MINERVA-MM）構成

資材の発注から入荷・在庫管理までを担う。主管は資材部。

## 1. 機能構成図

```mermaid
flowchart TB
    subgraph mm["MINERVA-MM"]
        pr["購買要求管理"]
        po["発注管理"]
        recv["入荷・検収"]
        inv["在庫管理"]
        stocktake["棚卸"]
    end

    subgraph external["連携先"]
        pp["MINERVA-PP<br/>所要量展開"]
        sd["MINERVA-SD<br/>出荷引当"]
        fi["MINERVA-FI<br/>会計連携"]
        ediS["仕入先 EDI<br/>(主要 25社)"]
        fax["FAX 発注<br/>(その他仕入先)"]
        wms["物流倉庫 WMS"]
    end

    pp -->|"購買要求<br/>(MRP 起票)"| pr
    pr -->|"承認フロー"| po
    po -->|"注文書"| ediS
    po -->|"注文書 PDF"| fax
    ediS -->|"納期回答"| po
    recv -->|"入庫実績"| inv
    inv <-->|"在庫照会・引当"| sd
    inv <-->|"倉庫在庫同期<br/>(30分間隔)"| wms
    recv -->|"検収イベント"| fi
    stocktake -->|"棚卸差異仕訳"| fi
    inv --> stocktake

    classDef main fill:#1e6bb8,color:#fff
    classDef ext fill:#f5f5f5,stroke:#999,stroke-dasharray: 5 5
    class pr,po,recv,inv,stocktake main
    class pp,sd,fi,ediS,fax,wms ext
```

## 2. 発注承認フロー

| 発注金額（税抜） | 承認者 |
| --- | --- |
| 〜50 万円 | 資材部 担当課長 |
| 〜300 万円 | 資材部長 |
| 300 万円超 | 資材部長 ＋ 管理本部長 |

- 承認は MINERVA のワークフロー機能で完結（紙・メール承認は廃止済み）
- **発注者と検収者は同一人物にできない**（職務分掌。システムで強制）

## 3. 在庫評価・棚卸

- 在庫評価は **月次総平均法**。月次締め後の入荷訂正は翌月扱い
- 実地棚卸は年 2 回（9 月・3 月）、循環棚卸は A ランク品目のみ月次
- 棚卸差異が金額 10 万円または数量 5% を超える品目は、差異理由の登録が必須

> ⚠️ **注意**: WMS との在庫同期は 30 分間隔の準リアルタイム。棚卸凍結中（実地棚卸日の 18:00〜翌 8:00）は同期を停止するため、この間の出荷指示は翌朝反映になる。
