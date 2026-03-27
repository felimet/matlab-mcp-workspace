# matlab-mcp-workspace

> **Skill: MATLAB MCP Workspace 結構化管理 + matlab-skills Plugin 整合**

[![matlab-mcp-core-server](https://img.shields.io/badge/matlab-matlab--mcp--core--server-blue?style=flat-square&logo=github)](https://github.com/matlab/matlab-mcp-core-server)
[![matlab-skills](https://img.shields.io/badge/matlab-skills-blue?style=flat-square&logo=github)](https://github.com/matlab/skills)

---

## 安裝

在 Claude Code 中執行以下指令：

```bash
# 1. 新增 Marketplace 來源
claude plugin marketplace add felimet/matlab-mcp-workspace

# 2. 進行安裝
claude plugin install matlab-mcp-workspace
```

---

## 為什麼需要這個 Skill

`matlab-mcp-core-server` 的 Initial Working Folder 是固定的。沒有任何結構約束的話，不同任務、不同對話生成的 `.m` 全部攤在同一層，三個月後你不知道哪個是哪個、哪個還能用、哪個是廢料。

| 問題 | 解法 |
|------|------|
| 跨任務程式碼混雜 | `projects\` / `_temp\` / `_shared\` 三分法 |
| 跨對話失去 context | README.md 狀態機 + Session Announcement |
| 函數被覆蓋 / 版本衝突 | 結構性改寫先備份 + Git 整合 |
| 每次重啟 path 消失 | `startup_workspace.m` 自動維護 `startup.m` |
| 路徑寫死 → 換機器就炸 | 所有程式碼用 `mfilename` 自我定位，零 hardcode |
| matlab-skills 不知道要寫去哪 | 本 skill 先跑確認路徑，再交棒給對應 skill |

---

## 與 matlab-skills Plugin 的分工

`matlab-skills` plugin 安裝了 MathWorks 官方的六個 skill，它們各自有很好的程式碼生成邏輯。本 skill 不跟它們競爭，而是作為前置層：

```
本 skill（先）                     matlab-skills（後）
────────────────────────           ──────────────────────────────
Session Announcement               生成 Live Script 格式
確認 / 建立 project 目錄            寫 *Test.m 測試類別
init_project.m 建立 tests\ 等       執行 buildtool / runtests
確認 src\ 存在（filter-design 需要） 設計 FIR/IIR 濾波器
判斷是否需先備份（optimizer 前）     套用 vectorization 技術
```

| 使用者的任務 | 先用本 skill | 再用 matlab-skills |
|-------------|-------------|-------------------|
| 寫 Live Script | 確認 / 建立路徑 | `matlab-live-script` |
| 建單元測試 | 確認 `tests\` 存在 | `matlab-test-creator` |
| 跑測試 / coverage | 確認在 project root | `matlab-test-execution` |
| 效能優化 | 判斷是否需先備份 | `matlab-performance-optimizer` |
| 建 HTML App | 確認 `src\html\` | `matlab-uihtml-app-builder` |
| 設計濾波器 | 確認 `src\` 存在 | `matlab-digital-filter-design` |

> [!NOTE]
> `matlab-digital-filter-design` 強制所有程式碼先寫成 `.m` 檔再執行，不可以直接傳入 `evaluate_matlab_code`。這表示它必須有一個 `src\` 目錄可以寫入——本 skill 的 `init_project.m` 就是為此而存在的前置條件。

---

## 路徑設計原則

> [!IMPORTANT]
> Workspace root 路徑**從不寫死**在任何程式碼或文件中。
> `scripts\` 裡的程式碼用 `mfilename('fullpath')` 反推自身位置，`src\` 裡的程式碼用 `get_ws_root()` 找到標記檔 `ws_config.m`。兩條路，都不需要 hardcode。

文件中所有 `<WORKSPACE_ROOT>` 均代表你的實際 workspace 根目錄，可以是任何路徑。

---

## Workspace 根目錄結構

```text
<WORKSPACE_ROOT>\
├── projects\                   # 正式任務（持久化，跨對話延續）
│   └── YYYYMMDD_<slug>\
│       ├── README.md           # 跨 session 記憶載體
│       ├── main.m
│       ├── buildfile.m         # buildtool 入口（matlab-test-execution）
│       ├── src\                # 模組化函數（按功能分子目錄）
│       │   ├── <module>\       # 功能模組（如 preprocessing\、training\）
│       │   ├── _backups\       # 結構性改寫備份
│       │   └── html\           # uihtml 前端（選用）
│       ├── tests\              # *Test.m（matlab-test-creator）
│       ├── docs\               # 專案說明文件
│       │   ├── architecture.md
│       │   ├── api.md
│       │   └── experiments.md
│       ├── data\
│       └── output\
├── _temp\                      # 臨時測試（≤ 14 天生命週期）
├── _shared\                    # 跨專案工具函數（永久）
├── _archive\                   # 已完成專案（封存）
├── scripts\                    # 本 skill 工具程式碼
├── ws_config.m                 # Workspace 標記檔（勿移動）
├── startup.m                   # 由 startup_workspace.m 自動維護
└── .gitignore
```

---

## 快速上手

```matlab
% 1. 每次 session 開始（腳本自己知道 workspace 在哪）
run('<WORKSPACE_ROOT>\skills\matlab-mcp-workspace\scripts\startup_workspace.m')

% 2. 新建 project（建立 src\、tests\、buildfile.m 等）
% → 修改 init_project.m 的 CONFIG 後執行

% 3. 繼續舊 project
run('<WORKSPACE_ROOT>\skills\matlab-mcp-workspace\scripts\list_workspace.m')
% → 確認 folder 名稱 → cd 進去 → 讀 README.md

% 4. 定期健康檢查
run('<WORKSPACE_ROOT>\skills\matlab-mcp-workspace\scripts\workspace_health.m')
```

> [!NOTE]
> 唯一需要你手填 `<WORKSPACE_ROOT>` 的地方只有啟動那一行。之後腳本全部自動定位。

---

## 常用腳本索引

| 腳本 | 何時用 |
|------|--------|
| `skills/matlab-mcp-workspace/scripts/startup_workspace.m` | 每次 session 開始 |
| `skills/matlab-mcp-workspace/scripts/init_project.m` | 建立新 project（含 tests\ + buildfile.m）|
| `skills/matlab-mcp-workspace/scripts/list_workspace.m` | 跨對話繼續前 |
| `skills/matlab-mcp-workspace/scripts/upgrade_temp.m` | Temp 決定保留時 |
| `skills/matlab-mcp-workspace/scripts/workspace_health.m` | 定期清理 |
| `skills/matlab-mcp-workspace/scripts/get_ws_root.m` | 在 `src\` 程式碼中取得 workspace root |

---

### references/

| Reference | 內容 |
|-----------|------|
| [`skills/matlab-mcp-workspace/references/01-workspace-structure.md`](skills/matlab-mcp-workspace/references/01-workspace-structure.md) | 目錄結構、slug 命名規則表、output 命名格式 |
| [`skills/matlab-mcp-workspace/references/02-session-protocol.md`](skills/matlab-mcp-workspace/references/02-session-protocol.md) | Announcement 模板、session 啟動流程、path 解析規則 |
| [`skills/matlab-mcp-workspace/references/03-project-lifecycle.md`](skills/matlab-mcp-workspace/references/03-project-lifecycle.md) | 狀態轉換表、phase 觸發/動作、temp 升級觸發 |
| [`skills/matlab-mcp-workspace/references/04-versioning.md`](skills/matlab-mcp-workspace/references/04-versioning.md) | .gitignore 模板、commit 格式、backup 判斷矩陣 |
| [`skills/matlab-mcp-workspace/references/05-shared-utilities.md`](skills/matlab-mcp-workspace/references/05-shared-utilities.md) | docstring 模板、分類對照表、`_shared/README.md` 格式 |
| [`skills/matlab-mcp-workspace/references/06-decision-guide.md`](skills/matlab-mcp-workspace/references/06-decision-guide.md) | 四級匹配表、消歧互動格式、信號表 |
| [`skills/matlab-mcp-workspace/references/07-plugin-integration.md`](skills/matlab-mcp-workspace/references/07-plugin-integration.md) | 各 skill 目錄對應表、完整 project 結構 |
| [`skills/matlab-mcp-workspace/references/08-project-docs.md`](skills/matlab-mcp-workspace/references/08-project-docs.md) | docs\ 職責表、Docs Update Prompt 觸發表 |

### docs/

| Docs | 內容 |
|------|------|
| [`docs/01-workspace-structure.md`](docs/01-workspace-structure.md) | 目錄結構完整說明（含邊界情境、範例）|
| [`docs/02-session-protocol.md`](docs/02-session-protocol.md) | Session 協議完整說明（含範例輸出）|
| [`docs/03-project-lifecycle.md`](docs/03-project-lifecycle.md) | 專案生命週期完整說明（含封存程式碼）|
| [`docs/04-versioning.md`](docs/04-versioning.md) | 版本控制完整說明（含 Git 操作指令）|
| [`docs/05-shared-utilities.md`](docs/05-shared-utilities.md) | Shared 函數完整說明（含工作流程）|
| [`docs/06-decision-guide.md`](docs/06-decision-guide.md) | 跨對話決策完整說明（含錯誤情境）|
| [`docs/07-plugin-integration.md`](docs/07-plugin-integration.md) | Plugin 整合完整說明（含 PathFixture）|
| [`docs/08-project-docs.md`](docs/08-project-docs.md) | 專案 docs\ 完整說明（含格式範本）|

---

## Skill 完整結構

```text
matlab-mcp-workspace/
├── .claude-plugin/                 # Claude Code Plugin 設定目錄
│   ├── plugin.json                 # Plugin manifest (設定名稱、版本等)
│   └── marketplace.json            # Marketplace 描述檔
├── .gitignore                      # Git 忽略清單
├── LICENSE                         # 授權條款 (BSD-3-Clause)
├── README.md                       # 本文件（導航入口）
├── docs/                           # 完整操作說明文檔
│   ├── 01-workspace-structure.md
│   ├── 02-session-protocol.md
│   ├── 03-project-lifecycle.md
│   ├── 04-versioning.md
│   ├── 05-shared-utilities.md
│   ├── 06-decision-guide.md
│   ├── 07-plugin-integration.md
│   └── 08-project-docs.md
└── skills/                         # Skill 核心資料夾
    └── matlab-mcp-workspace/
        ├── SKILL.md                # Claude 觸發與核心協議
        ├── references/             # 精簡版文件（表格 + 決策樹 + 模板）
        │   ├── 01-workspace-structure.md
        │   ├── 02-session-protocol.md
        │   ├── 03-project-lifecycle.md
        │   ├── 04-versioning.md
        │   ├── 05-shared-utilities.md
        │   ├── 06-decision-guide.md
        │   ├── 07-plugin-integration.md
        │   └── 08-project-docs.md
        └── scripts/                # MATLAB 工具程式碼
            ├── ws_config.m         # Workspace 根目錄標記（勿移動）
            ├── startup_workspace.m # 每次 session 開始時執行
            ├── init_project.m      # 建立新 project（含 tests\、docs\、buildfile.m）
            ├── list_workspace.m    # 跨對話繼續前列出專案狀態
            ├── upgrade_temp.m      # 將臨時測試升級為永久專案
            ├── workspace_health.m  # 定期清理檢查
            └── get_ws_root.m               # 取得 workspace 根目錄路徑
```

---

> [!NOTE]
> 所有 `.m` 程式碼僅依賴 base MATLAB，不需要任何 Toolbox。
> 所有 `.md` 文件遵循 GitHub Flavored Markdown（GFM）規範，含 Alert 語法。