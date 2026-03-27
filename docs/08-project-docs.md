# 08 — Project docs\ 說明文件規範

> [!IMPORTANT]
> 先講清楚這個 `docs\` 是什麼、不是什麼：
>
> - **是** project 內部的說明文件，給人讀的，README 是入口
> - **不是** skill 的 `references/`（那個是 Claude skill 架構本身的文件）
> - **不是** MATLAB 的 `help` docstring（那個是函數內部的技術說明）
>
> 三個東西雖然都是「文件」，用途完全不同。這份 `08-project-docs.md` 只說 project 內的 `docs\`。

---

## 為什麼需要 docs\

README.md 是跨 session 的「狀態板」——現在做到哪、下次要做什麼。它很薄、很快。

但 project 做久了，有些東西 README 放不下：
- 為什麼選 SVM 不選 Random Forest？（設計決策）
- `train_classifier.m` 的介面是什麼？（函數說明）
- 上次 RBF C=1.0 跑出 0.82，到底在哪裡卡住？（實驗記錄）

這些資訊如果沒有專門的地方放，就會散落在 Notes 裡，Notes 越來越長，下次 Claude 進來讀到的是一團亂碼。

**`docs\` 的存在就是讓 README 保持輕盈，讓真正有深度的說明有地方住。**

---

## docs\ 目錄結構

```
projects\YYYYMMDD_<slug>\
├── README.md                  ← 入口：狀態、pipeline 進度、快速摘要
└── docs\
    ├── architecture.md        ← 系統設計：整體結構、資料流、設計決策
    ├── api.md                 ← 函數介面：所有 src\ 函數的簽名與說明
    └── experiments.md         ← 實驗紀錄：參數配置、結果、結論
```

三個文件由 `init_project.m` 自動建立 stub 骨架，**骨架是空的**，等開發過程填入。不需要 project 一建立就把它們補滿，那反而是浪費時間——根本還沒有可以記的東西。

> [!NOTE]
> stub 的存在有個具體用途：讓 Docs Update Prompt（見下方）知道「這裡有文件」，可以給出具體引用（「更新 api.md 的 train_classifier 區塊」），而不是泛泛說「去建立一個文件」。

---

## Claude 在 Session 中如何使用 docs\

這是整份文件最重要的部分。

### 進入 EXISTING PROJECT 時的讀取順序

```
1. 讀 README.md
   → 確認 Status、找 Pipeline Overview 的中斷點、讀 Notes
   → 輸出 Session Announcement + Resuming 摘要

2. 按需讀 docs\
   → 使用者問到架構 / 設計 → 讀 architecture.md
   → 使用者問到函數用法 → 讀 api.md
   → 使用者問到上次的實驗結果 → 讀 experiments.md
   → 沒有明確需要 → 不讀（避免無意義地消耗 context）
```

Claude **不會**每次進來就把三個文件全部讀完。這些是「查閱用」的資料，不是每次都要全量載入的狀態。

### 改動程式碼後的行為

每次 Claude 完成程式碼改動，回應的**最末端**會出現 Docs Update Prompt，格式如下：

```
---
> [!NOTE] **[📝 Docs Update Prompt]**
> 本次改動建議同步更新以下文件：
> - `docs\api.md` — 新增 `train_classifier` 函數說明（輸入：features, labels；輸出：model）
> - `docs\architecture.md` — 演算法從 SVM 改為 Random Forest，更新設計決策區塊
>
> 確認後說「更新文件」，我會依序協助你補。如不需要，忽略即可。
```

### 說「更新文件」之後 Claude 做什麼

Claude 會依序讀對應的 docs 文件，找到對的位置，幫你補入說明。你不需要自己打開文件、找段落、貼格式——直接說要更新，Claude 做完給你確認。

如果 docs 文件的那個區塊已經有內容（函數之前寫過），Claude 會比對舊的和新的差異，**只更新有變化的部分**，不蓋掉整個區塊。

> [!TIP]
> 最省力的用法：每次跑完實驗有數字了，直接說「記錄這次實驗」，Claude 會把配置和結果整理成 experiments.md 的格式寫進去，你確認一下就好。手動記實驗是最容易被跳過的步驟，這樣做阻力最小。

---

## 各文件職責與格式

### README.md（入口）

跨 session 的快速定向。Claude 每次進入 `EXISTING PROJECT` 時第一個讀的就是這個。

關鍵欄位：

| 欄位 | 用途 | Claude 讀它做什麼 |
|------|------|-----------------|
| `Status` | active / completed / archived | 判斷是否該繼續開發 |
| `Pipeline Overview` | `[x]`已完成 `[ ]`待完成 | 找上次中斷點 |
| `Notes` | 當前狀態、已知問題、下一步 | Resuming 摘要的核心來源 |

> [!WARNING]
> Notes 欄位決定跨 session 連貫性的上限。寫「還在開發中」等於讓下次的 Claude 從零開始猜。最少要有：「上次做到哪」「卡在什麼」「下次要做什麼」三個維度。

---

### docs\architecture.md（系統設計）

記錄整個 project 的設計邏輯，讓三個月後的你或其他人不需要翻程式碼就能理解架構。

**標準格式：**

```markdown
# Architecture — YYYYMMDD_<slug>

## System Overview
<整個 pipeline 的一段話描述，說明它在做什麼、資料來自哪、輸出什麼>

## Data Flow
輸入: cattle_videos/ (MP4, 30fps)
    ↓ extract_silhouette.m
Silhouettes (binary frames)
    ↓ compute_gei.m
GEI features (128×128 double)
    ↓ train_classifier.m
SVM model → predictions

## Module Breakdown
| File | Purpose | Key Inputs | Key Outputs |
|------|---------|-----------|------------|
| `main.m` | Pipeline 主入口 | config struct | results.mat |
| `src/compute_gei.m` | GEI 特徵計算 | frames (M×N×T) | gei (M×N) |

## Design Decisions
### 為什麼選 SVM 而不是 CNN？
資料量有限（n=240），CNN 容易 overfit。
SVM + GEI 特徵在類似文獻中表現穩定，先跑通 baseline 再說。

## CI/CD
buildfile.m 目前只有 test task：
- 測試目錄：tests/
- 報告輸出：output/（html + cobertura）
```

**Docs Update Prompt 觸發時機：**

| 程式碼改動 | 要更新的 architecture.md 段落 |
|-----------|------------------------------|
| 演算法替換（SVM → RF） | Design Decisions |
| Pipeline 新增 / 移除 phase | Data Flow + Module Breakdown |
| `buildfile.m` 加新 task | CI/CD |

---

### docs\api.md（函數介面）

記錄 `src\` 所有公開函數的介面。目的是讓 Claude 和你自己在不打開程式碼的情況下知道每個函數怎麼用。

> [!NOTE]
> **api.md vs 函數內部 docstring 的差別：**
> - docstring（`% FUNCTION / INPUTS / OUTPUTS`）：給 MATLAB 的 `help` 指令用，隨函數存在
> - api.md：給「快速查閱介面」用，跨函數集中一處，在任何 editor 或對話中都能讀到
>
> 內容可以重疊，但 api.md 通常更精簡，docstring 可以更詳盡。

**每個函數的格式：**

```markdown
## `train_classifier`

**Purpose**: 用 GEI 特徵訓練 SVM 分類器，支援 RBF / polynomial kernel

**Signature**:
```matlab
[model, metrics] = train_classifier(features, labels, opts)
```

**Inputs**:
| 參數 | 型別 | 說明 |
|------|------|------|
| `features` | double, N×D | N 個樣本，D 維特徵向量 |
| `labels` | categorical, N×1 | 三類：健康 / 輕度 / 重度 |
| `opts.kernel` | char | 'rbf'（預設）或 'polynomial' |
| `opts.C` | double | SVM cost 參數，預設 1.0 |

**Outputs**:
| 參數 | 型別 | 說明 |
|------|------|------|
| `model` | ClassificationSVM | 訓練完的模型 |
| `metrics` | struct | .accuracy .f1_macro .cm（混淆矩陣）|

**Notes**:
- 需要 Statistics and Machine Learning Toolbox
- 輸入 features 未正規化時效果明顯下降，建議先跑 math_normalize_minmax
```

**Docs Update Prompt 觸發時機：**

| 程式碼改動 | 要更新的 api.md 段落 |
|-----------|---------------------|
| `src\` 新增 `.m` | 新增對應函數區塊 |
| 函數簽名改變（輸入 / 輸出） | 更新該函數的 Inputs / Outputs 表格 |
| 函數被廢棄 | 加上 `⚠️ DEPRECATED` 標記和替代函數名 |
| 加了新的 `opts` 欄位 | 更新 Inputs 表格 |

---

### docs\experiments.md（實驗紀錄）

記錄每次有具體數字的實驗。這是最容易被跳過、最後悔沒記的文件。

**每次實驗一個區塊，格式：**

```markdown
## Exp-001: SVM RBF baseline
- **Date**: 2025-03-27
- **Hypothesis**: RBF kernel 在有限資料下應有合理表現
- **Config**:
  - kernel: rbf, C=1.0, gamma='scale'
  - features: GEI 128×128，min-max normalized
  - split: 5-fold CV, leave-one-animal-out
- **Result**:
  - F1 (macro): 0.82 ± 0.04
  - Accuracy: 0.85
  - Fold 4 明顯偏低：F1=0.71
- **Conclusion**: 未達目標 0.90。Fold 4 差異大，懷疑 cow_027 資料品質問題。
- **Next**: ① 排除 cow_027 重跑 ② 試 polynomial kernel C=[0.1, 1, 10]
```

> [!TIP]
> **Next 這行是最重要的**。沒有它，這筆紀錄對下次 session 的 Claude 沒有任何幫助——它知道你做了什麼，但不知道你學到了什麼、打算怎麼繼續。

**Docs Update Prompt 觸發時機：**

| 程式碼 / 結果事件 | 要更新的 experiments.md 段落 |
|-----------------|------------------------------|
| 跑完測試拿到 metrics | 新增 Exp-N 區塊 |
| Coverage report 完成 | 在對應 Exp 區塊補 coverage 數字 |
| Pipeline 某步驟標記完成 | 在對應 Exp 補 Conclusion + Next |

---

## Docs Update Prompt 完整流程

```
Claude 改動程式碼
      ↓
回應最末端出現 Docs Update Prompt
（只列真正受影響的項目，說明要更新哪個段落）
      ↓
      ├─ 你說「更新文件」
      │     ↓
      │   Claude 讀對應的 docs 文件
      │   找到正確段落
      │   補入說明（新增函數 / 更新簽名 / 記錄實驗）
      │   輸出更新後的內容給你確認
      │
      └─ 你忽略
            ↓
          docs 維持現狀，不強制
```

> [!NOTE]
> Prompt 一定在回應末端，不插在程式碼中間。如果當次改動不需要更新任何文件（例如只是小幅 bug fix），不發出 Prompt——不製造不必要的噪音。

---

## 更新節奏建議

> [!IMPORTANT]
> 不需要每次改一行就更新文件。判斷標準很簡單：「三個月後第一次看這個 project 的人，需要知道這件事嗎？」需要 → 更新；不需要 → 跳過。

| 文件 | 適合更新的時機 |
|------|--------------|
| `README.md Notes` | 每次 session 結束前；達到里程碑時 |
| `architecture.md` | 設計有重大改變；演算法替換；子系統完成 |
| `api.md` | 新增函數；函數簽名改變；函數廢棄 |
| `experiments.md` | 有具體數字的實驗跑完 |

---

## 什麼情況不需要 docs\

> [!NOTE]
> 以下情況不建立 `docs\`，也不發出 Docs Update Prompt：
>
> - **`_temp\` session**：短生命週期，文件沒有意義
> - **單一函數的小 project**（< 3 個 `.m`）：README Notes 就夠了
> - **純測試 / 一次性驗算**：沒有需要長期維護的架構或實驗
>
> `init_project.m` 對所有正式 project 都建 `docs\` stub。但如果 project 最後很小，三個文件永遠保持空白也完全沒問題——stub 不佔什麼空間。

---

## 與 skill references/ 的概念區分

```
matlab-mcp-workspace skill
└── references/               ← Claude skill 架構的文件
    ├── 01-workspace-structure.md   （Claude 用來了解規則的）
    └── ...

MATLAB project（由 skill 管理）
└── docs/                     ← project 自己的說明文件
    ├── architecture.md             （你的研究的架構說明）
    └── ...
```

兩個 `references` / `docs` 的讀者不同：skill 的 `references/` 是給 Claude 讀的行為規範，project 的 `docs\` 是給人讀的研究說明。你不需要去動 skill 的 `references/`，那是 skill 本身的一部分。
