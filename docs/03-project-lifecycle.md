# 03 — Project Lifecycle

> [!IMPORTANT]
> 每個 project 走過 `active → completed → archived` 三個狀態，轉換需要明確觸發條件。Claude 在每次 session 讀取 README.md 時，必須確認當前狀態並在 Announcement 中正確反映。狀態不正確等於跨 session 記憶損壞。

---

## 狀態定義

| Status | 含義 | 允許操作 |
|--------|------|----------|
| `active` | 開發中，當前工作目標 | 讀寫全部 |
| `completed` | 目標達成，不再主動開發 | 唯讀，允許小修正 |
| `archived` | 已移至 `_archive\`，封存 | 唯讀 |

---

## Phase 1 — 建立新 Project

### 觸發條件

- 任務分類結果為 `NEW PROJECT`
- 或使用者明確說要開始新任務

### Step 1 — 決定 slug

根據任務描述提出 slug 候選，讓使用者確認後再執行初始化。命名規則見 `references/01-workspace-structure.md`。

### Step 2 — 執行 `scripts/init_project.m`

修改腳本 CONFIG 區塊三個變數，透過 `evaluate_matlab_code` 執行：

```matlab
% ── 僅需修改這三行 ───────────────────────────────────
project_slug = 'cattle_lameness_gei';
project_desc = '牛隻跛行多模態 GEI 特徵分類，ViT + cGAN 擴增。';
context_text = ['Dataset: 自建乳牛步態影片（n=240），3 class。', ...
                '目標：LEAVE-ONE-OUT CV F1 > 0.90。'];
% ────────────────────────────────────────────────────
```

腳本自動完成：
- 取得 workspace root（不需要硬編路徑）
- 建立 `projects\YYYYMMDD_<slug>\`、`src\`、`src\_backups\`、`data\`、`output\`
- 生成 README.md 骨架
- `addpath` 載入 `_shared\`
- `cd` 到新目錄

### Step 3 — 確認 Announcement

```
> **[MATLAB Workspace]**
> Mode   : NEW PROJECT
> Path   : <WORKSPACE_ROOT>\projects\20250327_cattle_lameness_gei\
> Status : new → active
> Reason : 新任務，slug 已與使用者確認。
```

---

## Phase 2 — 開發中（Active）

### 每次 Session 開始

1. 執行 `startup_workspace.m`
2. 執行 `list_workspace.m`，確認 project folder 名稱
3. `cd` 到 project root
4. 讀 README.md，擷取 Pipeline 中斷點與 Notes
5. 輸出 Announcement + Resuming 摘要

### README.md 維護責任

> [!NOTE]
> README.md 是跨 session 的唯一記憶載體。每次 session 達到里程碑，或對話即將結束時，Claude 應提示使用者更新以下欄位：
> - `Last Modified`：今日日期
> - `Pipeline Overview`：勾選完成項目
> - `Notes`：當前狀態、已知問題、下一步行動

**Notes 欄位好壞對比：**

```markdown
❌ 不夠用的 Notes：
## Notes
還在開發中。

✅ 真正有用的 Notes：
## Notes
- GEI 計算完成（compute_gei.m），單樣本 ~2.3s，可接受。
- SVM RBF C=1.0 在 fold1-3 均 ~0.82 F1，未達目標 0.90。
- 下次：試 polynomial kernel（C=[0.1, 1, 10]）或 Random Forest。
- 已知問題：cow_027 幀數不足 30，需排除或補全後再訓練。
```

### 版本衝突處理

見 [`references/04-versioning.md`](04-versioning.md)。

---

## Phase 3 — 完成（Completed）

### 觸發條件

- 使用者說「這個專案完成了」或「結果出來了」
- 目標指標達成（例如 F1 > 0.90）

### 執行動作

1. 更新 README.md：
   - `Status: active` → `Status: completed`
   - `Last Modified` 更新為今日
   - `Notes` 補上最終結果摘要、使用的最佳參數
2. Pipeline Overview 所有 `[ ]` 打勾或標記 N/A
3. 建議 Git commit（見 `references/04-versioning.md`）

> [!TIP]
> `completed` 不等於 `archived`。Completed 仍在 `projects\`，可被其他 project 參考。只有確定「永遠不會再主動開發」時才封存。

---

## Phase 4 — 封存（Archive）

### 觸發條件

- 使用者明確說「封存這個專案」
- `workspace_health.m` 標記為 completed 且超過 90 天未修改

### 執行動作

```matlab
%% 封存腳本（一次性操作，直接執行，不放在 scripts\ 中）
% 腳本自己知道 workspace root，不需要硬編
scripts_dir    = 'D:\_self-dev\matlab-mcp-working-folder\scripts';  % 唯一需要改的一行
addpath(scripts_dir);
WORKSPACE_ROOT = get_ws_root();

source_name = '20250301_cattle_lameness_gei';   % 替換為實際名稱
src = fullfile(WORKSPACE_ROOT, 'projects',  source_name);
dst = fullfile(WORKSPACE_ROOT, '_archive',  source_name);

if ~exist(src, 'dir'),  error('Project not found: %s', src);  end
if  exist(dst, 'dir'),  error('Archive destination exists: %s', dst);  end

% 封存前最後一次健康檢查
run(fullfile(WORKSPACE_ROOT, 'scripts', 'workspace_health.m'));

movefile(src, dst);
fprintf('Archived: %s\n  → %s\n', src, dst);
```

> [!CAUTION]
> 封存後 `_archive\` 視為**唯讀**。若需要基於舊 project 繼續開發，建立新 project 並在 README 記錄 `Forked from: _archive\<folder>`。

---

## Temp 升級協議 {#temp-升級協議}

### 升級觸發條件

以下任一情況主動提示升級：

| 信號 | 說明 |
|------|------|
| Temp session 超過 3 個 `.m` 檔案 | 規模已超出「臨時」的定義 |
| 使用者說「把這個留下來」 | 明確意圖 |
| Temp 中的函數被其他 project 引用 | 嚴禁 — 必須先升級才能引用 |
| 任務複雜度超出預期 | 發現需要子結構時主動提議 |

### 升級步驟

修改 `scripts/upgrade_temp.m` 的 CONFIG 區塊後執行：

```matlab
temp_slug    = '20250327_test_fft';    % 現有 temp 目錄名稱
project_slug = 'nir_fft_analysis';    % 新 project slug（不含日期）
project_desc = '...';
context_text = '...';
```

> [!WARNING]
> 腳本只能生成 README.md 骨架。`Context`、`Files`、`Notes` 欄位必須人工填寫——因為 Claude 無法回溯 temp session 中的開發意圖，只有你知道當時在做什麼。
