# 01 — Workspace Structure

> [!IMPORTANT]
> 文件中所有 `<WORKSPACE_ROOT>` 均代表你實際的 workspace 根目錄路徑（例如 `D:\_self-dev\matlab-mcp-working-folder`）。腳本永遠自動定位，**不需要在文件或程式碼中寫死這個路徑**。第一次使用只需要在 `matlab-mcp-core-server` 設定介面填入路徑，之後腳本靠 `ws_config.m` 標記自己找。

---

## 完整目錄樹

```
<WORKSPACE_ROOT>\                                  ← Workspace Root
│
├── projects\                                      ← 正式任務（持久化）
│   ├── 20250327_cattle_lameness_gei\
│   │   ├── README.md                              ← 入口：狀態、pipeline 進度
│   │   ├── main.m                                 ← Pipeline 主程式
│   │   ├── buildfile.m                            ← buildtool CI 設定
│   │   ├── docs\                                  ← 專案說明文件（README 是入口）
│   │   │   ├── architecture.md                    ← 系統設計、資料流、設計決策
│   │   │   ├── api.md                             ← src\ 函數介面說明
│   │   │   └── experiments.md                     ← 實驗紀錄、結果、結論
│   │   ├── src\                                   ← 模組化函數
│   │   │   ├── _backups\                          ← 結構性改寫前的快照
│   │   │   └── html\                             ← uihtml app 前端資源（選用）
│   │   ├── tests\                                 ← 測試類別（*Test.m）
│   │   ├── data\                                  ← 輸入資料（不進 Git）
│   │   └── output\                                ← 輸出產物（時間戳命名）
│   │
│   └── 20250315_schlieren_artifact_removal\
│       └── ...
│
├── _temp\                                         ← 臨時測試（≤ 14 天）
│   ├── 20250327_test_fft\
│   │   └── scratch.m                              ← 扁平結構，不建子目錄
│   └── 20250320_verify_imread\
│
├── _shared\                                       ← 跨專案工具函數（永久）
│   ├── README.md                                  ← 函數總索引（見 05-shared-utilities.md）
│   ├── image_processing\
│   ├── data_io\
│   ├── visualization\
│   ├── math_utils\
│   └── livestock\                                 ← 領域特定但跨 project 共用
│
├── _archive\                                      ← 封存完成的專案（視為唯讀）
│
├── scripts\                                       ← 本 skill 工具腳本
│   ├── startup_workspace.m
│   ├── init_project.m
│   ├── list_workspace.m
│   ├── upgrade_temp.m
│   ├── workspace_health.m
│   └── get_ws_root.m
│
├── ws_config.m                                    ← Workspace 標記檔（勿移動或重命名）
├── startup.m                                      ← 由 startup_workspace.m 自動維護
└── .gitignore                                     ← 見 04-versioning.md
```

> [!WARNING]
> `ws_config.m` 是所有 path discovery 的錨點。**絕對不要移動或重命名這個檔案**，否則 `get_ws_root()` 會找不到 workspace root，影響所有在 `src\` 內呼叫它的使用者程式碼。

---

## Project Slug 命名規則

### 格式

```
YYYYMMDD_<slug>
```

### Slug 構成規則

- 全小寫英文字母 + 底線（`_`），長度 ≤ 30 字元
- 禁止使用：大寫、空格、連字號（`-`）、版本號（`_v2`）
- 結構順序：`<domain>_<object>_<method>` 或 `<domain>_<task>`

| 任務描述 | ✅ 正確 slug | ❌ 錯誤示範 |
|----------|-------------|------------|
| 牛隻跛行 GEI 分類 | `cattle_lameness_gei` | `lameness-GEI`、`GEI_v2` |
| Schlieren 偽影去除 | `schlieren_artifact_removal` | `schlieren`、`ArtifactRemoval` |
| NIR 光譜 PLS 迴歸 | `nir_spectroscopy_pls` | `NIR_pls`、`spectra_reg` |
| ResNet-50 牛隻個體辨識 | `cattle_id_resnet50` | `cattle_recognition`、`resnet` |

> [!NOTE]
> **同一研究在不同日期出現兩個 folder 的判斷原則：**
> 研究**延續** → 用原始目錄，不建新的。
> 研究**重構或換方法** → 新目錄完全合理，日期前綴保證唯一性。

---

## Output 檔案命名規則

> [!WARNING]
> 嚴禁使用無語意名稱（`figure1.png`、`result.mat`、`output.csv`）。每次執行產生的輸出必須帶時間戳，確保**永不覆蓋前次結果**。

### 格式

```
<desc>_YYYYMMDD_HHMMSS.<ext>
```

### MATLAB 取得時間戳

```matlab
ts = datestr(now, 'yyyymmdd_HHMMSS');
% 輸出範例：'20250327_143022'
```

### 命名對照表

| 輸出類型 | ✅ 正確命名 | ❌ 錯誤示範 |
|----------|------------|------------|
| 混淆矩陣 | `gei_confusion_matrix_20250327_143022.png` | `cm.png` |
| 訓練結果 | `svm_rbf_fold3_20250327_150011.mat` | `result.mat` |
| 匯出 CSV | `lameness_predictions_20250327_160055.csv` | `export.csv` |

> [!TIP]
> 批次實驗若同秒多次 save，改用遞增索引：
> ```matlab
> run_files = dir(fullfile('output', 'results_run*.mat'));
> idx       = length(run_files) + 1;
> filename  = sprintf('results_run%03d_%s.mat', idx, ts);
> ```

---

## 邊界情境

### 同一 Project 的多子實驗

在 `src\` 內分子目錄，**不建多個 project**：

```
projects\20250327_nir_spectroscopy\src\
├── exp_beer_lambert\
├── exp_pls_regression\
└── exp_svm_classification\
```

### 大型共用資料集（> 100 MB）

不放進任何 project 的 `data\`，改用外部絕對路徑，並**只在 `main.m` 頂部定義**：

```matlab
% 外部資料根目錄 — 換機器時只需改這裡
DATA_ROOT  = 'D:\datasets\dairy_cattle';
VIDEO_ROOT = 'E:\recordings\2025';
```

> [!CAUTION]
> 外部路徑**只能定義在 `main.m` 頂部**，嚴禁在 `src\` 函數內部 hardcode。函數透過參數接收路徑，保持可攜性與可測試性。

---

## matlab-skills Plugin 目錄補充規則

### `tests\` 目錄

由 `init_project.m` 自動建立。放置 `matlab-test-creator` skill 生成的 `*Test.m` 測試類別。

> [!NOTE]
> `tests\` **進 Git 版控**（不在 `.gitignore` 中排除）。
> 測試程式碼是 project 的一部分，和 `src\` 同等重要。

### `buildfile.m`

由 `init_project.m` 在 project root 自動生成骨架，供 `matlab-test-execution` skill 的 `buildtool` 使用。

> [!NOTE]
> `buildfile.m` **進 Git 版控**。若 CI/CD 設定需要擴充（加 `check`、`package` 等 task），直接編輯 `buildfile.m`，等同修改 src\ 中的函數，適用相同的 backup 判斷規則。

### `src\html\` 目錄（選用）

僅在 project 含有 `matlab-uihtml-app-builder` 任務時建立，由 Claude 按需 `mkdir`，不由 `init_project.m` 預先建立。

### 詳細的各 skill 目錄對應規則

見 [`references/07-plugin-integration.md`](07-plugin-integration.md)。
