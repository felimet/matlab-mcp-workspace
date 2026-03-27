# 02 — Session Protocol

> [!IMPORTANT]
> Session Announcement 是每次對話中涉及 MATLAB 時**最先執行的動作**，優先於任何程式碼生成或工具呼叫。在不知道自己在哪個 project 的情況下就開始寫程式，是 workspace 混亂的最大來源。

---

## Session Announcement 格式

每次輸出嚴格遵守此格式：

```
> **[MATLAB Workspace]**
> Mode   : <模式>
> Path   : <WORKSPACE_ROOT>\<subfolder>\<project-folder>\
> Status : <狀態>
> Reason : <一句話說明分類依據>
```

### Mode 合法值

| Mode | 含義 |
|------|------|
| `NEW PROJECT` | 建立新正式 project |
| `EXISTING PROJECT` | 繼續已有 project |
| `TEMP SESSION` | 臨時測試 |
| `SHARED UTIL` | 撰寫 `_shared\` 工具函數 |
| `PENDING` | 分類需使用者確認 |

### 範例輸出

```
> **[MATLAB Workspace]**
> Mode   : EXISTING PROJECT
> Path   : <WORKSPACE_ROOT>\projects\20250301_cattle_lameness_gei\
> Status : active
> Reason : 使用者提及「繼續 GEI 分類器」，唯一符合的 project 為 cattle_lameness_gei。
```

```
> **[MATLAB Workspace]**
> Mode   : PENDING
> Path   : <WORKSPACE_ROOT>\ (待確認)
> Status : -
> Reason : 描述模糊，找到 2 個符合候選，需使用者確認（見下方列表）。
```

---

## Session 開始流程

```
對話觸發 MATLAB 任務
│
├─ Step 1：執行 startup_workspace.m
│           恢復 _shared 路徑 + 維護 startup.m
│
├─ Step 2：任務分類（見 SKILL.md §②）
│           若 EXISTING PROJECT → 執行 list_workspace.m
│
├─ Step 3：輸出 Session Announcement
│           Mode = PENDING 時立刻詢問，不得繼續
│
└─ Step 4：開始作業
    ├─ NEW PROJECT      → 執行 init_project.m
    ├─ EXISTING PROJECT → cd 到目標目錄 + 讀 README.md
    ├─ TEMP SESSION     → cd 到 _temp\YYYYMMDD_<desc>\ （不存在則 mkdir）
    └─ SHARED UTIL      → cd 到 _shared\<category>\
```

> [!TIP]
> 進入 `EXISTING PROJECT` 後，讀取 README.md 的 `## Notes` 和 `## Pipeline Overview`，在 Announcement 之後輸出中斷點摘要：
> ```
> > [Resuming] Pipeline step 3 待完成：SVM 訓練（kernel=RBF，fold 1-5）
> > [Last note] RBF C=1.0 平均 F1 ~0.82，低於目標。下次試 polynomial kernel。
> ```
> 這讓使用者不需要重述上次做到哪裡。

---

## Path Resolution

### 問題根源

`matlab-mcp-core-server` 每次啟動都可能是全新的 MATLAB process，`addpath` 不會持久化。同時，workspace root 路徑因人而異（不同機器、不同磁碟），**任何形式的 hardcode 都是設計錯誤**。

### 解法架構

```
ws_config.m                     放在 <WORKSPACE_ROOT>\ 的標記檔
    │
    ├─ scripts\ 內的腳本：
    │   用 mfilename('fullpath') 反推自身位置
    │   fileparts(fileparts(mfilename('fullpath'))) = WORKSPACE_ROOT
    │   → 不需要讀 ws_config，不需要任何硬編路徑
    │
    └─ src\ 內的使用者程式碼：
        先執行 startup_workspace.m（確保 scripts\ 在 path 上）
        再呼叫 get_ws_root() → 往上搜尋 ws_config.m，回傳 root
```

### 使用者程式碼中取得 root

```matlab
%% 在 project src\ 的任何 .m 檔案中
% 前提：startup_workspace.m 已在此 session 中被執行過，scripts\ 已在 path 上
WORKSPACE_ROOT = get_ws_root();

% 之後用 fullfile 建構任何路徑，永不 hardcode
shared_data = fullfile(WORKSPACE_ROOT, '_shared', 'data_io', 'io_load_mat_batch.m');
```

> [!CAUTION]
> 如果在 `src\` 程式碼中呼叫 `get_ws_root()` 但 `startup_workspace.m` 尚未執行，MATLAB 會報「Undefined function」。這不是 bug，是正確的失敗模式——它提醒你 session 初始化步驟被跳過了。

---

## 工作目錄規範

| 操作 | 工作目錄 |
|------|----------|
| 開發 project 程式碼 | `<WORKSPACE_ROOT>\projects\YYYYMMDD_<slug>\` |
| 撰寫 temp 測試 | `<WORKSPACE_ROOT>\_temp\YYYYMMDD_<desc>\` |
| 撰寫 shared 函數 | `<WORKSPACE_ROOT>\_shared\<category>\` |
| 執行 workspace 管理腳本 | 任意位置（腳本用 `mfilename` 自我定位）|

> [!NOTE]
> 執行含相對路徑的使用者腳本（如 `load('data/labels.mat')`）前，**必須確認 `pwd` 在正確的 project root**。每次 `cd` 後用 `disp(pwd)` 確認是好習慣。
