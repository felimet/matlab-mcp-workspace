# 01 — Workspace Structure（Lookup）

> 完整說明見 `docs/01-workspace-structure.md`

---

## Directory Tree

```
<WORKSPACE_ROOT>\
├── projects\           正式任務（持久化）
│   └── YYYYMMDD_<slug>\
│       ├── README.md
│       ├── main.m
│       ├── buildfile.m
│       ├── docs\
│       │   ├── architecture.md
│       │   ├── api.md
│       │   └── experiments.md
│       ├── src\              模組化函數（按功能分子目錄）
│       │   ├── <module>\    功能模組（如 preprocessing\、training\）
│       │   ├── _backups\    結構性改寫備份
│       │   └── html\        uihtml 前端（選用）
│       ├── tests\
│       ├── data\
│       └── output\
├── _temp\              臨時測試（≤ 14 天）
├── _shared\            跨專案工具函數（永久）
├── _archive\           封存完成的專案（唯讀）
├── scripts\            本 skill 工具腳本
├── ws_config.m         Workspace 標記檔（勿移動）
├── startup.m           由 startup_workspace.m 維護
└── .gitignore
```

---

## Slug 命名規則

| 規則 | 說明 |
|------|------|
| 格式 | `YYYYMMDD_<slug>` |
| 字元 | 全小寫 + `_`，≤ 30 字元 |
| 禁止 | 大寫、空格、`-`、版本號（`_v2`）|
| 結構 | `<domain>_<object>_<method>` 或 `<domain>_<task>` |

| 任務描述 | 正確 | 錯誤 |
|----------|------|------|
| 牛隻跛行 GEI 分類 | `cattle_lameness_gei` | `lameness-GEI`、`GEI_v2` |
| Schlieren 偽影去除 | `schlieren_artifact_removal` | `ArtifactRemoval` |
| NIR 光譜 PLS 迴歸 | `nir_spectroscopy_pls` | `NIR_pls` |

**同日期重複判斷**：研究延續 → 用原始目錄；研究重構/換方法 → 新目錄。

---

## Output 命名格式

```
<desc>_YYYYMMDD_HHMMSS.<ext>
```

```matlab
ts = datestr(now, 'yyyymmdd_HHMMSS');
```

| 輸出類型 | 正確 | 錯誤 |
|----------|------|------|
| 混淆矩陣 | `gei_confusion_matrix_20250327_143022.png` | `cm.png` |
| 訓練結果 | `svm_rbf_fold3_20250327_150011.mat` | `result.mat` |
| 匯出 CSV | `lameness_predictions_20250327_160055.csv` | `export.csv` |

同秒多次 save → 遞增索引：`results_run001_<ts>.mat`

---

## src\ 子目錄慣例

`src\` 按功能模組分子目錄，每個子目錄包含相關的 `.m` 函數。

| 情境 | src\ 結構 |
|------|-----------|
| 小型 project（≤ 5 函數）| `src\` 扁平，不分子目錄 |
| 中大型 project | `src\<module>\`（如 `preprocessing\`、`training\`、`evaluation\`）|
| 多子實驗 | `src\exp_<name>\` 分隔各實驗的獨立函數 |
| uihtml app | `src\html\`（前端資源，選用）|

### 子目錄命名

- 全小寫 + `_`，與 slug 規則一致
- 以功能描述（`preprocessing`、`feature_extraction`）而非技術描述（`step1`、`module_a`）

### addpath 注意事項

`startup_workspace.m` 和 `PathFixture` 使用 `IncludingSubfolders=true`，**自動包含所有 `src\` 子目錄**，不需要手動 `addpath` 每個子目錄。

---

## 邊界規則

| 情境 | 處理方式 |
|------|----------|
| 同 project 多子實驗 | `src\` 內分子目錄，不建多個 project |
| 大型資料集（> 100 MB）| 外部絕對路徑，僅在 `main.m` 頂部定義 |
| 外部路徑 | 禁止在 `src\` 函數內 hardcode，必須透過參數傳入 |
