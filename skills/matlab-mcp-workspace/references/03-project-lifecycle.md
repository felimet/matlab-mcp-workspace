# 03 — Project Lifecycle（Lookup）

> 完整說明見 `docs/03-project-lifecycle.md`

---

## 狀態轉換表

```
active ──[目標達成/使用者宣告完成]──> completed ──[明確封存/90天未修改]──> archived
```

| Status | 含義 | 允許操作 |
|--------|------|----------|
| `active` | 開發中 | 讀寫全部 |
| `completed` | 目標達成 | 唯讀，允許小修正 |
| `archived` | 已移至 `_archive\` | 唯讀 |

---

## Phase 觸發條件 + 動作清單

### Phase 1 — 建立（active）

| 觸發 | 任務分類 = `NEW PROJECT`，或使用者明確說新任務 |
|------|------|
| 動作 1 | 提出 slug 候選，使用者確認 |
| 動作 2 | 修改 `init_project.m` CONFIG（`project_slug`, `project_desc`, `context_text`）|
| 動作 3 | 執行 `init_project.m`（建結構 + README + addpath + cd）|
| 動作 4 | 輸出 Announcement（Mode: NEW PROJECT, Status: new → active）|

### Phase 2 — 開發中（active）

| 觸發 | 每次 session 進入 EXISTING PROJECT |
|------|------|
| 動作 1 | `startup_workspace.m` |
| 動作 2 | `list_workspace.m` → 確認 folder |
| 動作 3 | cd → 讀 README.md → 擷取中斷點 + Notes |
| 動作 4 | Announcement + Resuming 摘要 |
| 持續 | session 結束前提示更新 README.md（Last Modified / Pipeline / Notes）|

### Phase 3 — 完成（completed）

| 觸發 | 使用者宣告完成，或目標指標達成 |
|------|------|
| 動作 1 | README: `Status: active` → `completed`，更新 `Last Modified` |
| 動作 2 | Notes 補最終結果摘要、最佳參數 |
| 動作 3 | Pipeline Overview 全部打勾或 N/A |
| 動作 4 | 建議 Git commit |

### Phase 4 — 封存（archived）

| 觸發 | 使用者明確說封存，或 `workspace_health.m` 標記 completed + 90 天未修改 |
|------|------|
| 動作 1 | 執行 `workspace_health.m`（封存前檢查）|
| 動作 2 | `movefile(projects\<slug>, _archive\<slug>)` |
| 動作 3 | 若需基於舊 project 繼續 → 建新 project，README 記 `Forked from:` |

---

## Temp 升級觸發表

| 信號 | 說明 |
|------|------|
| `.m` 檔超過 3 個 | 規模已超出「臨時」定義 |
| 使用者說「把這個留下來」| 明確意圖 |
| 函數被其他 project 引用 | 嚴禁 — 必須先升級 |
| 任務複雜度超出預期 | 需要子結構時主動提議 |

**升級動作**：修改 `scripts/upgrade_temp.m` CONFIG（`temp_slug`, `project_slug`, `project_desc`, `context_text`）後執行。
