# 04 — Versioning

> [!IMPORTANT]
> 版本控制分兩層：**Git**（完整歷史，可回溯任意 commit）和 **backup 協議**（結構性改寫前的即時快照）。兩者互補，不互相取代。Git 是長期歷史，`src\_backups\` 是「還沒 commit，但已經在大幅改動」這個空窗期的安全網。

---

## 兩層策略概覽

```
為什麼需要兩層？
─────────────────────────────────────────────────────
MATLAB 的限制：函數名稱必須與檔名完全一致
→ 無法在同一目錄同時存放多個版本的同名函數
→ Git 是主要版本歷史（可回溯任意 commit）
→ src\_backups\ 是「正在改、還沒 commit」空窗期的快照
─────────────────────────────────────────────────────
```

---

## Part A — Git 整合

### Workspace 初始化

```bash
cd <WORKSPACE_ROOT>
git init
git add .gitignore README.md ws_config.m
git commit -m "chore: initialize workspace"
```

### .gitignore 模板

```gitignore
# ============================================================
# MATLAB MCP Workspace — .gitignore
# ============================================================

# --- 大型資料（路徑記錄在各 project 的 README Dependencies）
**/data/*.mat
**/data/*.csv
**/data/*.xlsx
**/data/*.h5
**/data/*.hdf5
**/data/*.tif
**/data/*.tiff
**/data/*.mp4
**/data/*.avi

# --- 輸出產物（時間戳唯一，不需要 Git 追蹤，佔用大量空間）
**/output/

# --- 臨時 session（短生命週期，不值得版控）
_temp/

# --- MATLAB 自動生成的暫存檔
*.asv
*.m~
*.mlx.lock
slprj/

# --- 系統檔
.DS_Store
Thumbs.db
desktop.ini

# --- 保留目錄結構（確保空目錄被 Git 追蹤）
!**/data/.gitkeep
!**/output/.gitkeep

# --- scripts\ 進版控（追蹤 skill 工具的改動）
# 不排除 scripts/
```

> [!NOTE]
> `data\` 和 `output\` 各放一個空的 `.gitkeep`，確保目錄本身進版控，但裡面的大型檔案不會意外 commit。

### Commit Message 規範

| 時機 | 格式 | 範例 |
|------|------|------|
| 完成一個可運行的 milestone | `feat(<slug>): <描述>` | `feat(cattle-lameness-gei): add GEI computation module` |
| 修 bug | `fix(<slug>): <描述>` | `fix(cattle-lameness-gei): correct silhouette frame alignment` |
| 新增 shared 函數 | `feat(shared): add <function_name>` | |
| 封存 project | `chore: archive <slug>` | |
| 更新 README / Notes | `docs(<slug>): update pipeline status and notes` | |
| 結構性重構 | `refactor(<slug>): <描述>` | |

> [!TIP]
> 不需要每次小改都 commit，但每次 session 結束前若有實質進展，commit 一次。這樣 `git log` 就是一條有意義的開發歷史。

### 查看特定 project 的歷史

```bash
git log --oneline -- projects/20250327_cattle_lameness_gei/
```

### 回溯特定函數的舊版本

```bash
git show <commit-hash>:projects/20250327_cattle_lameness_gei/src/train_classifier.m
```

> [!CAUTION]
> 不要在 `_archive\` 內的 project 上做局部 `git checkout`，這會污染 archive 的唯讀狀態。需要回溯時，建立新 branch 或新 project，並在 README 記錄來源。

---

## Part B — Backup 協議

### 使用時機

> [!NOTE]
> **小幅修改（bug fix、調整參數）→ 直接覆蓋**，Git 本身就是備份。
>
> **結構性改寫（函數簽名改變、演算法替換）→ 先備份再覆蓋**，這是 commit 前的即時安全網。

| 判斷維度 | 小幅（直接覆蓋） | 結構性（先備份）|
|----------|-----------------|-----------------|
| 函數簽名 | 不變 | 有改變（新增 / 移除 / 重新命名參數）|
| 核心演算法 | 微調 | 替換（SVM → Random Forest）|
| 輸入輸出格式 | 不變 | 有改變 |
| 影響範圍 | 局部幾行 | 整個函數體 |

**猶豫要不要備份 → 就備份**。一個備份檔代價極低，丟失可運行版本代價極高。

### 備份執行

```matlab
%% 結構性改寫前，執行此區塊
src_file = fullfile(pwd, 'src', 'train_classifier.m');
bak_dir  = fullfile(pwd, 'src', '_backups');
if ~exist(bak_dir, 'dir'), mkdir(bak_dir); end

bak_name = ['train_classifier_bak_', datestr(now, 'yyyymmdd'), '.m'];
bak_path = fullfile(bak_dir, bak_name);

% 同日第二次備份：加後綴避免覆蓋同天稍早的快照
if exist(bak_path, 'file')
    bak_name = ['train_classifier_bak_', datestr(now, 'yyyymmdd'), 'b.m'];
    bak_path = fullfile(bak_dir, bak_name);
end

copyfile(src_file, bak_path);
fprintf('[backup] Saved: %s\n', bak_path);
% ← 確認備份存在後，再開始改原始檔
```

### 備份命名格式

```
<original_name>_bak_YYYYMMDD.m
<original_name>_bak_YYYYMMDDb.m    ← 同日第二次
```

### 備份清理時機

> [!WARNING]
> `_backups\` 不是垃圾桶，備份必須定期清理。

- Project 狀態 → `completed`：保留最後 3 份，刪除其餘
- 備份超過 90 天且對應函數未再修改：可刪除
- 封存前：`workspace_health.m` 會列出備份過多的 project

---

## Part C — Shared 函數版本管理

> [!CAUTION]
> 修改 `_shared\` 函數影響所有 caller project。修改前必須先確認影響範圍（見 `05-shared-utilities.md`）。

### 後向不相容修改（Breaking Change）

當函數簽名必須改變，且有多個 project 在使用：

1. 建新版本：`img_extract_silhouette_v2.m`
2. 保留舊版直到所有 caller 遷移完成
3. 在 `_shared\README.md` 標記 deprecation
4. 遷移完成後：`v2` 改回原始檔名，刪除舊版

這是 `_shared\` 中**唯一允許同時存在兩個版本的情況**。
