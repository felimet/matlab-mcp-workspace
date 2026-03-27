# 04 — Versioning（Lookup）

> 完整說明見 `docs/04-versioning.md`

---

## .gitignore Template

```gitignore
# ============================================================
# MATLAB MCP Workspace — .gitignore
# ============================================================

# --- 大型資料
**/data/*.mat
**/data/*.csv
**/data/*.xlsx
**/data/*.h5
**/data/*.hdf5
**/data/*.tif
**/data/*.tiff
**/data/*.mp4
**/data/*.avi

# --- 輸出產物
**/output/

# --- 臨時 session
_temp/

# --- MATLAB 暫存檔
*.asv
*.m~
*.mlx.lock
slprj/

# --- 系統檔
.DS_Store
Thumbs.db
desktop.ini

# --- 保留目錄結構
!**/data/.gitkeep
!**/output/.gitkeep
```

---

## Commit Message 格式

| 時機 | 格式 | 範例 |
|------|------|------|
| 可運行 milestone | `feat(<slug>): <描述>` | `feat(cattle-lameness-gei): add GEI computation module` |
| 修 bug | `fix(<slug>): <描述>` | `fix(cattle-lameness-gei): correct frame alignment` |
| 新增 shared 函數 | `feat(shared): add <function_name>` | |
| 封存 project | `chore: archive <slug>` | |
| 更新 README/Notes | `docs(<slug>): update pipeline status and notes` | |
| 結構性重構 | `refactor(<slug>): <描述>` | |

---

## Backup 判斷矩陣

| 判斷維度 | 小幅 → 直接覆蓋 | 結構性 → 先備份 |
|----------|-----------------|-----------------|
| 函數簽名 | 不變 | 有改變 |
| 核心演算法 | 微調 | 替換 |
| 輸入輸出格式 | 不變 | 有改變 |
| 影響範圍 | 局部幾行 | 整個函數體 |

**猶豫 → 備份。** 備份代價極低，丟失可運行版本代價極高。

---

## Backup 命名格式

```
<original_name>_bak_YYYYMMDD.m
<original_name>_bak_YYYYMMDDb.m    ← 同日第二次
```

**清理時機**：completed → 保留最後 3 份；超過 90 天未修改 → 可刪除。

---

## Shared 函數 Breaking Change

1. 建新版本：`<name>_v2.m`
2. 保留舊版直到所有 caller 遷移
3. `_shared\README.md` 標記 deprecation
4. 遷移完成 → `v2` 改回原始檔名，刪除舊版
