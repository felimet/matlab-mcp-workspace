# 02 — Session Protocol（Lookup）

> 完整說明見 `docs/02-session-protocol.md`

---

## Announcement Template

```
> **[MATLAB Workspace]**
> Mode   : <mode>
> Path   : <WORKSPACE_ROOT>\<subfolder>\<project-folder>\
> Status : <status>
> Reason : <一句話分類依據>
```

---

## Mode 合法值

| Mode | 含義 |
|------|------|
| `NEW PROJECT` | 建立新正式 project |
| `EXISTING PROJECT` | 繼續已有 project |
| `TEMP SESSION` | 臨時測試 |
| `SHARED UTIL` | 撰寫 `_shared\` 工具函數 |
| `PENDING` | 分類需使用者確認 |

---

## Session 啟動流程

```
對話觸發 MATLAB 任務
│
├─ 1. 執行 startup_workspace.m
│     恢復 _shared 路徑 + 維護 startup.m
│
├─ 2. 任務分類（SKILL.md Task Classification）
│     EXISTING PROJECT → 執行 list_workspace.m
│
├─ 3. 輸出 Session Announcement
│     Mode = PENDING → 立刻詢問，不得繼續
│
└─ 4. 開始作業
    ├─ NEW PROJECT      → init_project.m
    ├─ EXISTING PROJECT → cd + 讀 README.md
    ├─ TEMP SESSION     → cd _temp\YYYYMMDD_<desc>\（不存在則 mkdir）
    └─ SHARED UTIL      → cd _shared\<category>\
```

EXISTING PROJECT 進入後，輸出 Resuming 摘要：
```
> [Resuming] Pipeline step N 待完成：<描述>
> [Last note] <Notes 最後一條>
```

---

## Path Resolution

| 場景 | 方法 |
|------|------|
| `scripts\` 內腳本 | `fileparts(fileparts(mfilename('fullpath')))` → `WORKSPACE_ROOT` |
| `src\` 內使用者程式碼 | 先執行 `startup_workspace.m`，再呼叫 `get_ws_root()` |
| 錨點 | `ws_config.m`（勿移動或重命名）|

---

## 工作目錄對應

| 操作 | pwd 應在 |
|------|----------|
| 開發 project | `<WORKSPACE_ROOT>\projects\YYYYMMDD_<slug>\` |
| temp 測試 | `<WORKSPACE_ROOT>\_temp\YYYYMMDD_<desc>\` |
| shared 函數 | `<WORKSPACE_ROOT>\_shared\<category>\` |
| workspace 管理腳本 | 任意（腳本自我定位）|
