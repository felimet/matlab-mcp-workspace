# 06 — Decision Guide

> [!IMPORTANT]
> 這份文件處理最容易出錯的場景：新對話提及「繼續某個專案」，但語意模糊。**錯誤的匹配比沒有分類更糟**——程式碼跑進錯誤的 project，debug 時你不知道問題在哪裡。不確定時，**停下來問，不要猜**。

---

## 跨對話延續完整流程

```
Step 1 — 執行 list_workspace.m
         取得所有 project folder 名稱與 README Status
         ↓
Step 2 — 匹配分析（見下方四級分類）
         ↓
Step 3 — 根據匹配結果行動
         ↓
Step 4 — Session Announcement + 讀 README.md + 輸出 Resuming 摘要
```

---

## 匹配邏輯（四級）

| 等級 | 條件 | 行動 |
|------|------|------|
| **完全符合** | 使用者原話出現完整 slug | 直接使用，Announcement 說明依據 |
| **強符合** | ≥ 2 個 slug 關鍵詞出現、唯一一個 folder 符合 | 直接使用，Announcement 說明匹配理由 |
| **弱符合 / 多重符合** | 多個 folder 都部分符合，或描述過短 | **停止 → 列出候選 → 等使用者確認** |
| **無符合** | 語意完全沒有重疊 | 視為新任務，執行分類決策樹 |

> [!CAUTION]
> 「強符合唯一」不代表可以不確認。描述太短（例如「繼續那個」）時，即使只有一個 folder，也要先列出讓使用者確認。確認成本是幾秒鐘；猜錯的成本是整個 session 的程式碼進了錯誤的 project。

---

## 多重符合時的互動格式

列出候選後**停止等待回應**，不執行任何檔案操作：

```
找到 N 個可能相關的專案，請確認要繼續哪一個：

1. `20250301_cattle_lameness_gei`      建立：2025-03-01  狀態：active
   → "牛隻跛行多模態 GEI 特徵分類"

2. `20250315_cattle_id_resnet50`       建立：2025-03-15  狀態：active
   → "ResNet-50 牛隻個體辨識"

3. `20250320_cattle_behavior_lstm`     建立：2025-03-20  狀態：completed
   → "牛隻行為序列 CNN-BiLSTM 分類"

請輸入編號（1 / 2 / 3），或：
  `new`  → 建立全新 project
  `temp` → 使用臨時目錄
```

---

## 延續信號識別

### 這些信號 → 繼續舊 project

| 信號類型 | 範例 |
|----------|------|
| 顯性引用 | 「繼續上次的 GEI 分類」「那個 schlieren 專案」|
| 代詞指涉（有明確對應） | 「那個 ViT 分類器」（若 ViT project 存在）|
| Phase 2+ 任務暗示 | 「現在要加入 data augmentation」（暗示 pipeline 已存在）|
| 過去式 + 繼續 | 「上次完成了特徵提取，現在要訓練分類器」|

### 這些信號 → 新任務

| 信號類型 | 範例 |
|----------|------|
| 明確說新 | 「我想做一個…」「從頭開始…」「全新任務」|
| 無語意重疊 | 與所有現有 folder 的 slug 完全無關 |
| 顯性說明 | 「這和之前的沒有關係」|

### 模糊地帶 → 一律詢問

- 只說「繼續」沒有具體描述
- 描述只出現一個 slug 關鍵詞
- 所提功能在多個 project 中都存在

---

## 進入 Existing Project 的標準動作

確認 project folder 後：

**1. 切換目錄 + 恢復路徑**

```matlab
cd('<WORKSPACE_ROOT>\projects\20250301_cattle_lameness_gei');
run('<WORKSPACE_ROOT>\scripts\startup_workspace.m');
```

> [!NOTE]
> 這是唯一需要使用者自行填入 `<WORKSPACE_ROOT>` 的地方。實際使用時，Claude 從 `list_workspace.m` 的輸出中取得完整絕對路徑，不需要手動拼接。

**2. 讀取 README.md + 輸出摘要**

從 README.md 擷取並在 Announcement 後輸出：
- `Status`：若為 `completed`，詢問是否確定繼續開發
- `Pipeline Overview`：找最後一個 `[x]` 後的第一個 `[ ]`，標記為目前目標
- `Notes`：完整輸出

```
> **[MATLAB Workspace]**
> Mode   : EXISTING PROJECT
> Path   : <WORKSPACE_ROOT>\projects\20250301_cattle_lameness_gei\
> Status : active
> Reason : 'cattle' 與 'lameness' 均出現在使用者描述中，唯一符合。
>
> [Resuming] 目前進度：Pipeline step 3（SVM 訓練）— 尚未完成
> [Last note] RBF C=1.0 平均 F1 ~0.82，低於目標。下次試 polynomial kernel。
```

---

## 常見錯誤情境

### 「繼續」但沒說繼續哪個

```
❌ 直接猜一個或建新 project
✅ 執行 list_workspace.m，列出所有 active project，等確認
```

### 找到「很像但不確定」的 folder

```
❌ 直接進去開發
✅ 列出 folder 名稱 + README 第一行 Description，問「是這個嗎？」
```

### 任務名稱和 slug 差很遠但語意相關

例如使用者說「牛隻步態分析」，folder 叫 `20250301_cattle_lameness_gei`：

```
✅ 匹配並說明：
   「找到 20250301_cattle_lameness_gei，
   README 描述是『牛隻跛行 GEI 特徵分類』，是這個嗎？」
```

### README.md Notes 欄位空白

```
✅ 繼續進入 project，但在 Announcement 後補一行：
   「[Warning] README.md 的 Notes 欄位是空的。
   這次 session 結束前建議更新，否則下次對話無法快速 resume。」
```
