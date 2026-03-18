# タスクコメント機能 API設計書

## 概要

タスクに対してコメントを追加・管理する機能のAPI仕様を定義します。

**ベースURL**: `https://api.taskmanager.example.com/v1/create

---

## コメント追加

タスクに新しいコメントを追加します。

### エンドポイントについて
```
POST /tasks/{task_id}/comments
```

### 認証
**必須**: Bearer token

### パスパラメータの説明

| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| task_id | string | ○ | コメントを追加するタスクのID |

### リクエストヘッダー

```
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### リクエストボディ

```json
{
  "content": "スライドテンプレートを共有しました"
}
```

#### フィールド仕様

| フィールド | 型 | 必須 | 制約 | 説明 |
|-----------|------|------|------|------|
| content | string | ○ | 最小1文字、最大2000文字 | コメントの本文 |

### レスポンス

#### 成功時 (201 Created)

```json
{
  "id": "cmt_1111111111",
  "content": "スライドテンプレートを共有しました",
  "author": {
    "id": "usr_2222222222",
    "name": "佐藤花子",
    "email": "sato@example.com"
  },
  "created_at": "2025-12-16T14:30:00Z",
  "updated_at": "2025-12-16T14:30:00Z"
}
```

#### レスポンスフィールド

| フィールド | 型 | 説明 |
|-----------|------|------|
| id | string | コメントの一意識別子 |
| content | string | コメントの本文 |
| author | object | コメント投稿者の情報 |
| author.id | string | 投稿者のユーザーID |
| author.name | string | 投稿者の名前 |
| author.email | string | 投稿者のメールアドレス |
| created_at | string | コメント作成日時 (ISO 8601形式) |
| updated_at | string | コメント最終更新日時 (ISO 8601形式) |

### エラーレスポンス

#### 400 Bad Request - リクエストが不正

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "リクエストボディが不正です",
    "details": [
      {
        "field": "content",
        "message": "コメント内容は必須です"
      }
    ]
  }
}
```

#### 401 Unauthorized - 認証エラー

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "認証トークンが無効または期限切れです"
  }
}
```

#### 403 Forbidden - アクセス権限なし

```json
{
  "error": {
    "code": "FORBIDDEN",
    "message": "このタスクへのアクセス権限がありません"
  }
}
```

#### 404 Not Found - タスクが存在しない

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "指定されたタスクが見つかりません"
  }
}
```

#### 422 Unprocessable Entity - バリデーションエラー

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "入力値が不正です",
    "details": [
      {
        "field": "content",
        "message": "コメントは2000文字以内で入力してください"
      }
    ]
  }
}
```

#### 429 Too Many Requests - レート制限超過

```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "APIリクエストの制限を超過しました。しばらくしてから再度お試しください"
  }
}
```

### リクエスト例

#### cURL

```bash
curl -X POST https://api.taskmanager.example.com/v1/tasks/tsk_9876543210/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{
    "content": "スライドテンプレートを共有しました"
  }'
```

#### JavaScript (fetch)

```javascript
const response = await fetch('https://api.taskmanager.example.com/v1/tasks/tsk_9876543210/comments', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  },
  body: JSON.stringify({
    content: 'スライドテンプレートを共有しました'
  })
});

const comment = await response.json();
console.log(comment);
```

#### Python (requests)

```python
import requests

url = "https://api.taskmanager.example.com/v1/tasks/tsk_9876543210/comments"
headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
data = {
    "content": "スライドテンプレートを共有しました"
}

response = requests.post(url, json=data, headers=headers)
comment = response.json()
print(comment)
```

### ビジネスルール

1. **認証必須**: コメントを追加するには有効な認証トークンが必要です
2. **アクセス権限**: ユーザーは自分がアクセス可能なタスクにのみコメントを追加できます
3. **文字数制限**: コメントは1文字以上2000文字以内である必要があります
4. **空白のみ不可**: 空白文字のみのコメントは受け付けません
5. **レート制限**: ユーザーは1分間に最大30件のコメントを追加できます
6. **通知**: コメント追加時、タスクの担当者および関係者に通知が送信されます

### セキュリティ考慮事項

- すべてのリクエストはHTTPS経由で行う必要があります
- JWTトークンは安全に保管し、クライアント側でログに出力しないでください
- XSS対策として、コメント表示時にHTMLエスケープ処理を実施してください
- SQLインジェクション対策は実装済みです

### パフォーマンス

- **平均レスポンスタイム**: 100ms以下
- **最大レスポンスタイム**: 500ms
- **可用性**: 99.9%

### Webhook連携

コメントが追加されると、以下のWebhookイベントが発火します。

**イベント名**: `comment.created`

```json
{
  "event": "comment.created",
  "timestamp": "2025-12-16T14:30:00Z",
  "data": {
    "comment": {
      "id": "cmt_1111111111",
      "content": "スライドテンプレートを共有しました",
      "task_id": "tsk_9876543210",
      "author": {
        "id": "usr_2222222222",
        "name": "佐藤花子"
      },
      "created_at": "2025-12-16T14:30:00Z"
    }
  }
}
```

---

## 変更履歴

### v1.0.0 (2025-12-17)
- 初回リリース
- コメント追加機能の実装