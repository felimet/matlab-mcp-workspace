# 07 — Plugin Integration（matlab-skills）

> [!IMPORTANT]
> `matlab-mcp-workspace` 與 `matlab-skills` plugin 的分工是：
> **workspace skill 管「在哪裡」，matlab-skills 的各 skill 管「怎麼寫」。**
> 每次生成任何 `.m`、`.html`、`.js` 等檔案前，Session Announcement 必須先完成，
> 確認目標路徑後，再交棒給對應的 skill 執行。

---

## 分工架構

```
使用者任務進來
      │
      ▼
matlab-mcp-workspace（本 skill）
  ① Session Announcement
  ② 任務分類 → 確認目標目錄
  ③ 如有需要，執行 init_project.m / startup_workspace.m
      │
      ▼
matlab-skills 對應 skill 接手
  ④ 按各 skill 的格式規則生成程式碼
  ⑤ 將產出寫入 workspace 規範的目錄位置
```

---

## 各 Skill 目錄對應規則

### 1. `matlab-live-script`

> 觸發：生成含文字說明的 `.m` 教學腳本、Live Script

| 輸出類型 | 寫入位置 |
|----------|----------|
| Live Script（主程式 / 教學） | `projects\<slug>\src\<name>.m` |
| Live Script（探索性草稿） | `_temp\YYYYMMDD_<desc>\<name>.m` |
| 共用範例模板 | `_shared\<category>\<name>.m` |

> [!NOTE]
> Live Script 使用 `%[text]` 語法，這是 `matlab-live-script` skill 的格式規則。
> workspace skill 只管路徑，格式由 `matlab-live-script` 負責。

---

### 2. `matlab-test-creator`

> 觸發：生成 `*Test.m` 測試檔案

| 輸出類型 | 寫入位置 |
|----------|----------|
| 測試類別（`*Test.m`） | `projects\<slug>\tests\<name>Test.m` |
| PathFixture 中的 `srcFolder` | `fullfile(fileparts(fileparts(mfilename('fullpath'))), 'src')` |

> [!IMPORTANT]
> `matlab-test-creator` 預設將測試放在 `tests/` 資料夾。
> `init_project.m` 已自動建立 `tests\` 子目錄，**但只有在建立新 project 時才會存在**。
> 若在舊 project 中第一次加測試，先確認 `tests\` 是否存在，不存在則 `mkdir`：
> ```matlab
> tests_dir = fullfile(pwd, 'tests');
> if ~exist(tests_dir, 'dir'), mkdir(tests_dir); end
> ```

PathFixture 的 `srcFolder` 推算方式（`test-creator` skill 已內建此模式）：

```matlab
methods (TestClassSetup)
    function addSourceToPath(testCase)
        % mfilename('fullpath') → tests\myFunctionTest.m 的絕對路徑
        % fileparts × 2        → project root
        % fullfile(..., 'src') → src\ 目錄
        srcFolder = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'src');
        testCase.applyFixture(matlab.unittest.fixtures.PathFixture(srcFolder, ...
            IncludingSubfolders=true));
    end
end
```

這個路徑推算與 workspace 的目錄結構完全對應，不需要任何硬編路徑。

---

### 3. `matlab-test-execution`

> 觸發：執行測試、收集 coverage、設定 CI/CD

| 資源 | 位置 |
|------|------|
| 測試目錄 | `projects\<slug>\tests\` |
| 原始碼目錄 | `projects\<slug>\src\` |
| buildfile | `projects\<slug>\buildfile.m` |
| Coverage 報告輸出 | `projects\<slug>\output\coverage-report_YYYYMMDD_HHMMSS\` |

`init_project.m` 會在 project root 生成 `buildfile.m` 骨架，`test-execution` skill 可直接使用或擴充。

執行測試前，確認 working directory 在 project root：

```matlab
% 確認 pwd 在 project root（含 buildfile.m 的那層）
disp(pwd)
buildtool test
```

> [!WARNING]
> `test-execution` 的 `buildtool` 需要 `buildfile.m` 在 **current directory**。
> 執行前必須先 `cd` 到 project root，不能從其他目錄呼叫。

Coverage report 寫入 `output\` 時加時間戳：

```matlab
ts = datestr(now, 'yyyymmdd_HHMMSS');
report_dir = fullfile('output', ['coverage-report_', ts]);

runner.addPlugin(CodeCoveragePlugin.forFolder('src', ...
    'Producing', CoverageReport(report_dir)));
```

---

### 4. `matlab-performance-optimizer`

> 觸發：優化效能、profile 程式碼、vectorization

| 操作類型 | 行為 |
|----------|------|
| 優化現有函數 | 原地修改 `src\<name>.m`，若為結構性重寫先備份至 `src\_backups\` |
| 生成 profiling 腳本 | 寫入 `src\profile_<name>.m`（非輸出，不用時間戳）|
| 儲存 profiling 結果 | 寫入 `output\profile_<name>_YYYYMMDD_HHMMSS.mat` |
| Benchmark 對照腳本 | 寫入 `src\benchmark_<name>.m` |

> [!NOTE]
> 效能優化改動的是 `src\` 中的函數本體，屬於「結構性改寫」範疇。
> 判斷是否需要先備份的標準見 `references/04-versioning.md §Part B`。

---

### 5. `matlab-uihtml-app-builder`

> 觸發：建立 HTML/JavaScript + MATLAB backend 的互動 App

| 輸出類型 | 寫入位置 |
|----------|----------|
| MATLAB App 主程式（`.m`） | `projects\<slug>\src\<appname>_app.m` |
| HTML/CSS/JS 前端 | `projects\<slug>\src\html\<appname>.html` |
| 共用 HTML 元件（跨 project） | `_shared\uihtml_components\<component>.html` |
| App 輸出資料 | `projects\<slug>\output\<desc>_YYYYMMDD_HHMMSS.<ext>` |

> [!NOTE]
> `src\html\` 是 uihtml app 專用的子目錄，在含有此類任務的 project 中才建立。
> 建立方式：
> ```matlab
> html_dir = fullfile(pwd, 'src', 'html');
> if ~exist(html_dir, 'dir'), mkdir(html_dir); end
> ```

---

### 6. `matlab-digital-filter-design`

> 觸發：設計 FIR/IIR 濾波器、訊號去噪

| 輸出類型 | 寫入位置 |
|----------|----------|
| 濾波器設計腳本（`.m`） | `projects\<slug>\src\filter_<name>.m` |
| 濾波器驗證腳本（`.m`） | `projects\<slug>\src\filter_<name>_validate.m` |
| 頻率響應圖 | `projects\<slug>\output\filter_<name>_response_YYYYMMDD_HHMMSS.png` |
| 濾係數存檔 | `projects\<slug>\output\filter_<name>_coeffs_YYYYMMDD_HHMMSS.mat` |

> [!IMPORTANT]
> `matlab-digital-filter-design` skill 有一個硬性規則：**所有多行 MATLAB 程式碼必須寫成 `.m` 檔再用 `run_matlab_file` 執行，不得直接傳入 `evaluate_matlab_code`**。
> 這表示 workspace 必須先建好 project 目錄，讓 skill 知道要寫去哪裡。
> Session Announcement 完成後，才能讓 `digital-filter-design` 開始寫檔。

---

## 完整 Project 目錄樹（含 plugin 整合後的結構）

```
projects\20250327_cattle_lameness_gei\
│
├── README.md                          ← 專案入口
├── main.m                             ← Pipeline 主程式
├── buildfile.m                        ← buildtool CI 設定（test-execution 用）
│
├── src\                               ← 所有 .m 函數
│   ├── _backups\                      ← 結構性改寫備份
│   ├── html\                          ← uihtml app 的前端資源（選用）
│   ├── compute_gei.m
│   ├── train_classifier.m
│   ├── filter_motion_artifact.m       ← digital-filter-design 產出
│   ├── filter_motion_artifact_validate.m
│   └── profile_train_classifier.m    ← performance-optimizer 產出
│
├── tests\                             ← 測試目錄（test-creator 產出）
│   ├── computeGeiTest.m
│   └── trainClassifierTest.m
│
├── data\                              ← 輸入資料（不進 Git）
└── output\                            ← 輸出產物（時間戳命名）
    ├── coverage-report_20250327_143022\
    ├── filter_motion_artifact_response_20250327_150011.png
    └── svm_rbf_results_20250327_160055.mat
```

---

## Session 中多個 Skills 共存的行為規範

> [!NOTE]
> 單一對話可能同時觸發多個 skills。例如：「幫我寫一個牛隻步態分析的 Live Script，並加上效能優化」會同時觸發 `matlab-live-script` 和 `matlab-performance-optimizer`。

處理順序：

```
1. matlab-mcp-workspace 先完成 Session Announcement + 確認目錄
2. 各 skill 按任務需求依序生成檔案
3. 所有生成的檔案都寫入 workspace 規範的位置（本文件 §各 Skill 目錄對應規則）
4. 若生成了測試，檢查 tests\ 目錄是否存在
5. 若修改了既有 .m，判斷是否需要先備份（見 04-versioning.md）
```

> [!TIP]
> 判斷「這個 skill 生出來的東西要放哪」時，**以產物的性質決定路徑，而不是以觸發它的 skill 決定**。
> 例如：`performance-optimizer` 最終產出的是一個改良過的 `.m` 函數，放 `src\`，
> 不是放 `output\`（output 只放「結果資料」，不放「程式碼」）。
