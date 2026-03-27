---
name: matlab-mcp-workspace
description: This skill MUST be used as the FIRST skill whenever Claude uses matlab-mcp-core-server to write, execute, debug, or manage any MATLAB code. Triggers on any mention of MATLAB, .m files, MATLAB scripts, MATLAB functions, "run this in MATLAB", "write a MATLAB", "debug MATLAB", "start a MATLAB project", "organize MATLAB workspace", "list MATLAB projects", or any task that produces MATLAB code files. Also triggers when asked to clean up, archive, inspect, or run health checks on the workspace. Enforces structured workspace under a configurable root (not hardcoded). THIS SKILL HANDLES WHERE FILES GO. The matlab-skills plugin (matlab-live-script, matlab-test-creator, matlab-test-execution, matlab-performance-optimizer, matlab-uihtml-app-builder, matlab-digital-filter-design) handles HOW the code is written. Always run this skill first to establish the workspace path, then let the appropriate matlab-skills skill handle code generation. Never skip workspace setup even when a matlab-skills skill is the primary trigger.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob

license: BSD-3-Clause (see LICENSE)
metadata:
  author: Jia-Ming Zhou
  version: "1.0"
---

# MATLAB MCP Workspace Management

> [!NOTE]
> Workspace root 路徑在此 skill 中一律以 `<WORKSPACE_ROOT>` 表示。
> 實際路徑由程式碼透過 `mfilename('fullpath')` 自我定位，**不存在任何硬編路徑**。
> 詳見 `references/02-session-protocol.md`。

---

## 1. Mandatory Session Announcement

每次對話中涉及 MATLAB 的**第一個動作**，必須是輸出此 Announcement，優先於任何程式碼生成或工具呼叫。

```
> **[MATLAB Workspace]**
> Mode   : NEW PROJECT | EXISTING PROJECT | TEMP SESSION | SHARED UTIL | PENDING
> Path   : <WORKSPACE_ROOT>\<subfolder>\<project-folder>\
> Status : active | new | temp
> Reason : <一句話 — 為什麼這樣分類>
```

分類需要使用者確認時，輸出 `Mode: PENDING` 並立刻詢問，不得在回應前猜測。

---

## 2. Task Classification

```
MATLAB task 進來
│
├─ 明確提及既有 project 名稱或 slug？
│   └─ YES → 跨對話延續協議  →  references/06-decision-guide.md
│
├─ 快速測試 / 語法確認 / 不確定是否保留？
│   └─ YES → _temp\YYYYMMDD_<desc>\     （扁平結構，無子目錄）
│
├─ 跨 project 可複用的工具函數？
│   └─ YES → _shared\<category>\        →  references/05-shared-utilities.md
│
└─ 正式研究 / 明確目標 / 會跨對話延續？
    └─ YES → projects\YYYYMMDD_<slug>\  →  執行 skills/matlab-mcp-workspace/scripts/init_project.m
```

**分類模糊時預設為 `_temp`**，在 Announcement 說明理由，詢問是否升級為 project。

---

## 3. Workspace Root Structure

```
<WORKSPACE_ROOT>\
├── projects\          持久化正式任務
│   └── YYYYMMDD_<slug>\
│       ├── README.md        跨 session 記憶載體（入口）
│       ├── main.m
│       ├── buildfile.m
│       ├── docs\            專案說明文件（README 是入口）
│       │   ├── architecture.md
│       │   ├── api.md
│       │   └── experiments.md
│       ├── src\             模組化函數（按功能分子目錄）
│       │   ├── <module>\    功能模組（如 preprocessing\、training\）
│       │   ├── _backups\    結構性改寫備份
│       │   └── html\        uihtml 前端資源（選用）
│       ├── tests\
│       ├── data\
│       └── output\
├── _temp\             臨時測試（14 天生命週期）
├── _shared\           跨專案工具函數
├── _archive\          封存完成的專案
├── skills\                    
│   └── matlab-mcp-workspace\  
│       ├── scripts\           本 skill 工具腳本
│       │   └── ws_config.m    Workspace 標記檔（勿移動）
│       └── references\        Claude lookup 文件
├── startup.m          由 startup_workspace.m 自動維護
└── .gitignore
```

---

## 4. Path Resolution（重要）

`scripts\` 內所有程式碼使用以下方式取得 workspace root，**不依賴任何硬編路徑**：

```matlab
% 方法 A：scripts\ 內的程式碼（最直接）
scripts_dir    = fileparts(mfilename('fullpath'));   % 程式碼自身所在的 scripts\
plugin_dir     = fileparts(scripts_dir);            % 上一層為 matlab-mcp-workspace\
skills_dir     = fileparts(plugin_dir);             % 上一層為 skills\
WORKSPACE_ROOT = fileparts(skills_dir);             % 再上一層即為 root

% 方法 B：project src\ 內的使用者程式碼（需先執行 startup_workspace）
WORKSPACE_ROOT = get_ws_root();   % 往上搜尋 ws_config.m 標記檔
```

---

## 5. Hard Rules

1. **Workspace root 禁止直接建立任何 `.m` 或資料檔案**
2. **Output 檔案一律使用時間戳命名，永不覆蓋**
3. **結構性改寫必須先備份至 `src\_backups\`**
4. **Session Announcement 是對話中最先執行的動作**
5. **每個新 project 必須同步生成 README.md**
6. **`_temp\` 不得被其他 project 的程式碼 `addpath` 或 `run`**
7. **任何程式碼中禁止硬編 workspace root 的完整路徑**
8. **每次改動程式碼或檔案後，在回應最末端輸出 Docs Update Prompt（見 9. Docs Update Prompt）**

---

## 6. Script Reference

| 程式碼 | 何時呼叫 |
|------|----------|
| `skills/matlab-mcp-workspace/scripts/startup_workspace.m` | 每次 session 開始 |
| `skills/matlab-mcp-workspace/scripts/init_project.m` | 每個新 project |
| `skills/matlab-mcp-workspace/scripts/list_workspace.m` | 跨對話延續前 |
| `skills/matlab-mcp-workspace/scripts/upgrade_temp.m` | Temp 決定保留時 |
| `skills/matlab-mcp-workspace/scripts/workspace_health.m` | 定期清理 / 封存前 |
| `skills/matlab-mcp-workspace/scripts/get_ws_root.m` | `src\` 程式碼取得 root path |

---

## 7. References Routing

以下 `references/` 文件為 Claude 快速查表用的純 lookup 資料（表格 + 決策樹 + 模板）。
對應的完整敘述文檔在 `docs/`，供人類閱讀。

| 主題 | Reference（Claude lookup）| Docs（人類閱讀）|
|------|--------------------------|-----------------|
| 目錄結構、slug 命名、output 命名 | `skills/matlab-mcp-workspace/references/01-workspace-structure.md` | `docs/01-workspace-structure.md` |
| Session Announcement、path 管理 | `skills/matlab-mcp-workspace/references/02-session-protocol.md` | `docs/02-session-protocol.md` |
| 建立 → 開發 → 完成 → 封存 | `skills/matlab-mcp-workspace/references/03-project-lifecycle.md` | `docs/03-project-lifecycle.md` |
| Git 整合、.gitignore、backup 協議 | `skills/matlab-mcp-workspace/references/04-versioning.md` | `docs/04-versioning.md` |
| `_shared\` 函數標準、docstring、registry | `skills/matlab-mcp-workspace/references/05-shared-utilities.md` | `docs/05-shared-utilities.md` |
| 跨對話匹配、消歧流程 | `skills/matlab-mcp-workspace/references/06-decision-guide.md` | `docs/06-decision-guide.md` |
| **matlab-skills plugin 整合規則** | **`skills/matlab-mcp-workspace/references/07-plugin-integration.md`** | **`docs/07-plugin-integration.md`** |
| **專案 docs\ 文件規範** | **`skills/matlab-mcp-workspace/references/08-project-docs.md`** | **`docs/08-project-docs.md`** |

---

## 8. 與 matlab-skills Plugin 的分工

`matlab-skills` plugin 已安裝 6 個 MathWorks 官方 skill。**本 skill 與它們的關係是：**

```
本 skill 先跑               matlab-skills 的對應 skill 後跑
─────────────────           ──────────────────────────────
確認工作目錄                 生成程式碼
分類 project/temp/shared     套用正確格式
Session Announcement         執行測試 / profile / 設計濾波器
init_project.m 建結構        把產出寫入正確位置
```

### 觸發對應表

| 使用者的需求 | 本 skill 負責 | 交棒給哪個 skill |
|-------------|--------------|----------------|
| 寫 Live Script | 確認路徑 | `matlab-live-script` |
| 建單元測試 | 確認 `tests\` 存在 | `matlab-test-creator` |
| 跑測試 / coverage | 確認在 project root | `matlab-test-execution` |
| 優化效能 | 判斷是否需先備份 | `matlab-performance-optimizer` |
| 建 HTML App | 確認 `src\html\` 存在 | `matlab-uihtml-app-builder` |
| 設計濾波器 | 確認 `.m` 要寫進 `src\` | `matlab-digital-filter-design` |

> [!IMPORTANT]
> `matlab-digital-filter-design` skill 強制要求所有程式碼寫成 `.m` 檔再執行（不得直接傳入 `evaluate_matlab_code`）。這意味著 workspace 的 `src\` 目錄必須在它開始工作之前就存在。本 skill 的 Session Announcement + `init_project.m` 是前置條件，不可跳過。

### 每個 skill 的輸出落點

詳見 `references/07-plugin-integration.md`（各 skill 的目錄對應規則、PathFixture 設定、buildfile 整合）。

---

## 9. Docs Update Prompt

每次 Claude 完成程式碼或檔案的改動後，**在回應的最末端**輸出一個 Docs Update Prompt。這個 prompt 是提示，不是自動寫入——判斷與更新的決定權在使用者。

### 觸發條件對照表

| 改動類型 | 提示更新哪裡 |
|----------|------------|
| `src\` 新增 `.m` 函數 | `docs\api.md`（補函數說明）|
| 現有函數**簽名改變**（輸入 / 輸出有變）| `docs\api.md`（更新介面描述）|
| 演算法邏輯被替換（非小幅修改）| `docs\architecture.md`（更新設計說明）|
| Pipeline 某個步驟完成（README `[ ]` → `[x]`）| `docs\experiments.md` + `README.md Notes` |
| `buildfile.m` 結構改動 | `docs\architecture.md`（更新 CI 流程說明）|
| `_shared\` 新增 / 修改函數 | `_shared\README.md`（更新 index）|
| `tests\` 新增測試類別 | `docs\api.md`（補對應函數的測試覆蓋說明）|

### Prompt 輸出格式

```
---
> [!NOTE] **[Docs Update Prompt]**
> 本次改動建議同步更新以下文件：
> - `docs\api.md` — 新增 `<function_name>` 函數說明
> - `docs\architecture.md` — <簡述改動點>
>
> 確認後直接說「更新文件」，我會依序協助你補。如不需要，忽略即可。
```

### 行為細節

- **只列真正受影響的項目**——不要每次都把全部四個文件都列出來。沒有受影響的就不提。
- **說明要具體**——不要只寫「更新 api.md」，要說「新增 `train_classifier` 函數說明（輸入：features, labels; 輸出：model）」。
- **Prompt 一定在回應末端**——不插在程式碼中間，不在 Announcement 之後就跳出來。
- **`_temp\` 的改動不觸發**——temp session 沒有 `docs\`，不提示。
