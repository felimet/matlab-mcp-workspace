# 07 — Plugin Integration（Lookup）

> 完整說明見 `docs/07-plugin-integration.md`

---

## 處理順序

```
1. matlab-mcp-workspace：Announcement + 分類 + 確認目錄
2. init_project.m / startup_workspace.m（如有需要）
3. matlab-skills 對應 skill 接手生成程式碼
4. 產出寫入 workspace 規範位置
```

---

## 各 Skill 目錄對應表

### 1. matlab-live-script

| 輸出類型 | 寫入位置 |
|----------|----------|
| 主程式/教學 Live Script | `projects\<slug>\src\<name>.m` |
| 探索性草稿 | `_temp\YYYYMMDD_<desc>\<name>.m` |
| 共用範例模板 | `_shared\<category>\<name>.m` |

### 2. matlab-test-creator

| 輸出類型 | 寫入位置 |
|----------|----------|
| 測試類別 | `projects\<slug>\tests\<name>Test.m` |
| PathFixture srcFolder | `fullfile(fileparts(fileparts(mfilename('fullpath'))), 'src')` |

舊 project 第一次加測試 → 先確認 `tests\` 存在，不存在則 `mkdir`。

### 3. matlab-test-execution

| 資源 | 位置 |
|------|------|
| 測試目錄 | `projects\<slug>\tests\` |
| 原始碼 | `projects\<slug>\src\` |
| buildfile | `projects\<slug>\buildfile.m` |
| Coverage 報告 | `projects\<slug>\output\coverage-report_YYYYMMDD_HHMMSS\` |

`buildtool` 需 pwd 在 project root（含 `buildfile.m`）。

### 4. matlab-performance-optimizer

| 操作 | 位置 |
|------|------|
| 優化函數（原地修改） | `src\<name>.m`（結構性重寫先備份）|
| profiling 腳本 | `src\profile_<name>.m` |
| profiling 結果 | `output\profile_<name>_YYYYMMDD_HHMMSS.mat` |
| benchmark 腳本 | `src\benchmark_<name>.m` |

### 5. matlab-uihtml-app-builder

| 輸出類型 | 寫入位置 |
|----------|----------|
| App 主程式 | `projects\<slug>\src\<appname>_app.m` |
| HTML/CSS/JS | `projects\<slug>\src\html\<appname>.html` |
| 共用 HTML 元件 | `_shared\uihtml_components\<component>.html` |
| App 輸出 | `projects\<slug>\output\<desc>_YYYYMMDD_HHMMSS.<ext>` |

`src\html\` 按需 `mkdir`，不由 `init_project.m` 預建。

### 6. matlab-digital-filter-design

| 輸出類型 | 寫入位置 |
|----------|----------|
| 設計腳本 | `projects\<slug>\src\filter_<name>.m` |
| 驗證腳本 | `projects\<slug>\src\filter_<name>_validate.m` |
| 頻率響應圖 | `projects\<slug>\output\filter_<name>_response_YYYYMMDD_HHMMSS.png` |
| 濾係數 | `projects\<slug>\output\filter_<name>_coeffs_YYYYMMDD_HHMMSS.mat` |

所有程式碼**必須寫成 `.m` 檔再執行**，不得 `evaluate_matlab_code`。

---

## 完整 Project 目錄樹（Plugin 整合後）

```
projects\YYYYMMDD_<slug>\
├── README.md
├── main.m
├── buildfile.m                        test-execution 用
├── src\                               模組化函數（按功能分子目錄）
│   ├── <module>\                      功能模組（如 preprocessing\、training\）
│   │   └── <function>.m
│   ├── _backups\                      結構性改寫備份
│   ├── html\                          uihtml 前端（選用）
│   ├── filter_<name>.m                digital-filter-design
│   ├── filter_<name>_validate.m       digital-filter-design
│   ├── profile_<name>.m              performance-optimizer
│   └── benchmark_<name>.m            performance-optimizer
├── tests\
│   └── <name>Test.m                   test-creator
├── docs\
│   ├── architecture.md
│   ├── api.md
│   └── experiments.md
├── data\
└── output\
    ├── coverage-report_YYYYMMDD_HHMMSS\
    ├── filter_<name>_response_YYYYMMDD_HHMMSS.png
    └── <desc>_YYYYMMDD_HHMMSS.<ext>
```

---

## 多 Skill 共存規範

```
1. workspace skill 先完成 Announcement + 確認目錄
2. 各 skill 按需求依序生成
3. 產出按性質決定路徑（非按觸發 skill）
4. 生成測試 → 檢查 tests\ 存在
5. 修改 .m → 判斷是否先備份（04-versioning.md）
```
