# 06 — Decision Guide（Lookup）

> 完整說明見 `docs/06-decision-guide.md`

---

## 跨對話延續流程

```
1. 執行 list_workspace.m → 取得所有 project folder + README Status
2. 匹配分析（四級分類）
3. 根據匹配結果行動
4. Announcement + 讀 README.md + Resuming 摘要
```

---

## 四級匹配表

| 等級 | 條件 | 行動 |
|------|------|------|
| **完全符合** | 原話出現完整 slug | 直接使用，Announcement 說明依據 |
| **強符合** | ≥ 2 個 slug 關鍵詞，唯一 folder 符合 | 直接使用，說明匹配理由 |
| **弱符合/多重符合** | 多個 folder 部分符合，或描述過短 | **停止 → 列候選 → 等確認** |
| **無符合** | 語意完全無重疊 | 視為新任務，執行分類決策樹 |

---

## 多重符合互動格式

```
找到 N 個可能相關的專案，請確認要繼續哪一個：

1. `YYYYMMDD_<slug>`      建立：YYYY-MM-DD  狀態：<status>
   → "<README 第一行描述>"

2. ...

請輸入編號，或：
  `new`  → 建立全新 project
  `temp` → 使用臨時目錄
```

列出後 **停止等待**，不執行任何檔案操作。

---

## 延續/新任務信號表

### → 繼續舊 project

| 信號類型 | 範例 |
|----------|------|
| 顯性引用 | 「繼續上次的 GEI 分類」|
| 代詞指涉（有對應） | 「那個 ViT 分類器」|
| Phase 2+ 暗示 | 「現在要加入 data augmentation」|
| 過去式 + 繼續 | 「上次完成了特徵提取，現在要訓練分類器」|

### → 新任務

| 信號類型 | 範例 |
|----------|------|
| 明確說新 | 「從頭開始…」「全新任務」|
| 無語意重疊 | 與所有 slug 完全無關 |
| 顯性說明 | 「這和之前的沒有關係」|

### → 模糊 → 一律詢問

- 只說「繼續」無具體描述
- 只出現一個 slug 關鍵詞
- 功能在多個 project 中存在

---

## Existing Project 進入動作

1. `cd` + `startup_workspace.m`
2. 讀 README.md → Status / Pipeline 中斷點 / Notes
3. Status = `completed` → 詢問是否確定繼續
4. Notes 空白 → 警告，session 結束前建議更新
