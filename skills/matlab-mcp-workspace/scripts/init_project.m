%% init_project.m — 初始化新 Project 目錄結構
% ============================================================
% VERSION  : 3.0.0 | 2025-03-27
% PURPOSE  : 建立一個符合 workspace 規範的新 project 目錄。
%            同時為 matlab-skills plugin 的各 skill 建好所需結構：
%              - tests\           matlab-test-creator 的輸出目錄
%              - buildfile.m      matlab-test-execution 的 buildtool 入口
%
%            完整子目錄一覽：
%              src\          所有 .m 函數（matlab-skills 各 skill 的產出均放這裡）
%              src\_backups\ 結構性改寫前的即時快照
%              tests\        *Test.m 測試類別（test-creator 產出，進版控）
%              data\         輸入資料（不進 Git，但目錄本身進 Git）
%              output\       所有輸出產物（時間戳命名，不進 Git）
%
% USAGE    : 修改下方 CONFIG 區塊後，透過 evaluate_matlab_code 執行。
%
% DESIGN NOTE — 零 hardcode 路徑：
%   本腳本放在 scripts\ 底下。
%   mfilename('fullpath') 回傳腳本本身的絕對路徑，與 pwd 無關。
%   fileparts 兩次就到 workspace root——
%   不管 workspace 在哪個磁碟哪個目錄，這段推算永遠成立。
% ============================================================

%% ── CONFIG ── 每次只需修改這三個變數 ────────────────────────
%
% project_slug : 小寫英文 + 底線，不含日期前綴，≤ 30 字元
%                例：'cattle_lameness_gei'、'nir_spectroscopy_pls'
% project_desc : 一句話描述（寫進 README.md 的 Description 欄）
% context_text : 2-3 句背景說明（寫進 README.md 的 Context 段落）

project_slug = 'my_project';
project_desc = 'One-sentence description of this project.';
context_text = 'Background: what problem, what dataset, what goal.';

%% ── END CONFIG ───────────────────────────────────────────────

%% ── 1. 自我定位：推算 workspace root ────────────────────────
%
% scripts_dir    → 本腳本自身所在的 scripts\ 目錄
% WORKSPACE_ROOT → 上一層，也就是 workspace 根目錄
%
% 這是整個「零 hardcode」設計的核心兩行。
% 腳本永遠知道自己在哪裡，所以永遠知道 workspace 在哪裡。

scripts_dir    = fileparts(mfilename('fullpath'));
WORKSPACE_ROOT = fileparts(scripts_dir);

%% ── 2. 組出 project 完整路徑 ─────────────────────────────────
%
% YYYYMMDD 前綴保證唯一性：
% 同一個 slug 在不同日期開始新版本，日期前綴就能區分兩者，不衝突。

today_str    = datestr(now, 'yyyymmdd');
project_name = [today_str, '_', project_slug];
project_path = fullfile(WORKSPACE_ROOT, 'projects', project_name);

%% ── 3. 冪等性保護：已存在則不重複建立 ───────────────────────
%
% 同名目錄已存在時，直接 cd 過去並提示使用者。
% 不讓腳本在「應該繼續用舊的」的情況下默默蓋掉已有的結構。

if exist(project_path, 'dir')
    warning(['[init_project] 目錄已存在，不重複建立。\n', ...
             '路徑：%s\n', ...
             '若要建立同名的新版本，請在 slug 中加入不同識別詞。'], ...
             project_path);
    cd(project_path);
    fprintf('[init_project] 已切換至現有目錄：%s\n', project_path);
    return;
end

%% ── 4. 建立標準子目錄 ────────────────────────────────────────
%
% docs\ 是 project 層級的說明文件資料夾，README.md 是入口。
%   architecture.md → 系統設計、資料流、設計決策
%   api.md          → src\ 函數介面說明（供跨 session 快速查閱）
%   experiments.md  → 實驗紀錄：配置、結果、結論
%   這三個文件由下方 §7 自動生成 stub 骨架，內容在開發中逐步填入。
%
% tests\ 的設計說明：
%   matlab-test-creator skill 預設把 *Test.m 放在 tests\ 下。
%   test-creator 內建的 PathFixture 樣板是：
%     fileparts(fileparts(mfilename('fullpath'))) → project root
%     fullfile(..., 'src')                        → src\
%   所以 tests\ 和 src\ 必須在同一個 project root 下，才能讓
%   PathFixture 的相對推算正確找到 src\。
%
% src\_backups\ 是版本衝突協議的快照存放點（見 references/04-versioning.md）。

subdirs = {
    'src',
    fullfile('src', '_backups'),   % 結構性改寫前的快照
    'tests',                       % matlab-test-creator 的輸出目錄
    'docs',                        % 專案說明文件（README 是入口）
    'data',                        % 輸入資料（大型檔案不進 Git）
    'output'                       % 所有輸出產物（時間戳命名）
};

for i = 1:length(subdirs)
    mkdir(fullfile(project_path, subdirs{i}));
end
fprintf('[init_project] 子目錄建立完成：%s\n', project_path);

%% ── 5. 在 data\ 和 output\ 放入 .gitkeep ────────────────────
%
% Git 本身不追蹤空目錄。.gitkeep 讓目錄進版控，
% 確保換機器 git clone 後結構完整，不需要手動重建。
%
% tests\ 不需要 .gitkeep：
%   它很快就會有 *Test.m，不會是空目錄。

for keep_dir = {'data', 'output'}
    fid = fopen(fullfile(project_path, keep_dir{1}, '.gitkeep'), 'w');
    fclose(fid);
end

%% ── 6. 生成 buildfile.m 骨架 ─────────────────────────────────
%
% matlab-test-execution skill 使用 buildtool 執行測試和 CI/CD。
% buildtool 要求 buildfile.m 必須在 current directory（project root）。
%
% 這裡只加一個 'test' task，保持最小可用狀態。
% 如果日後需要 'check'（Code Issues Task）或 'package' 等 task，
% 直接編輯 buildfile.m，等同修改 src\ 函數，適用相同的 backup 判斷。

buildfile_path = fullfile(project_path, 'buildfile.m');
fid = fopen(buildfile_path, 'w', 'n', 'UTF-8');
fprintf(fid, '%% buildfile.m — buildtool CI/CD 設定\r\n');
fprintf(fid, '%% 由 init_project.m v3.0.0 自動生成\r\n');
fprintf(fid, '%% 搭配 matlab-test-execution skill 使用\r\n');
fprintf(fid, '%% 執行方式：在 project root 執行 buildtool 或 buildtool test\r\n\r\n');
fprintf(fid, 'function plan = buildfile\r\n');
fprintf(fid, '    plan = buildplan(localfunctions);\r\n\r\n');
fprintf(fid, '    %% test task：執行 tests\\ 下的所有測試，產出 HTML + Cobertura 報告\r\n');
fprintf(fid, '    %% Coverage report 輸出至 output\\——符合 workspace 時間戳命名規範\r\n');
fprintf(fid, '    plan("test") = matlab.buildtool.tasks.TestTask("tests", ...\r\n');
fprintf(fid, '        SourceFiles     = "src", ...\r\n');
fprintf(fid, '        ReportFormat    = ["html", "cobertura"], ...\r\n');
fprintf(fid, '        OutputDirectory = "output");\r\n\r\n');
fprintf(fid, '    plan.DefaultTasks = "test";\r\n');
fprintf(fid, 'end\r\n');
fclose(fid);
fprintf('[init_project] buildfile.m 骨架已生成。\n');

%% ── 7. 生成 docs\ stub 文件 ──────────────────────────────────
%
% docs\ 是 project 層級的說明文件資料夾，README 是入口。
% 這裡生成三個骨架文件：
%
%   architecture.md → 系統設計、資料流、設計決策
%   api.md          → src\ 函數介面說明（跨 session 快速查閱）
%   experiments.md  → 實驗紀錄：配置、結果、結論
%
% 骨架是空的，等待開發過程中填入。
% Docs Update Prompt（見 SKILL.md §⑨）會在 Claude 改動程式碼後提示你更新。
%
% 設計選擇：生成 stub 而非完全空白，是為了讓 Claude 知道「這裡有文件可更新」，
% 讓 Docs Update Prompt 的引用更具體（「更新 api.md 的 Section X」而非「建立文件」）。

% ── architecture.md ──
arch_path = fullfile(project_path, 'docs', 'architecture.md');
fid = fopen(arch_path, 'w', 'n', 'UTF-8');
fprintf(fid, '# Architecture — %s\r\n\r\n', project_name);
fprintf(fid, '<!-- 填入時機：完成第一個可運行的 pipeline 後 -->\r\n\r\n');
fprintf(fid, '## System Overview\r\n\r\n');
fprintf(fid, '<!-- 一段話描述整個 pipeline 在做什麼 -->\r\n\r\n');
fprintf(fid, '## Data Flow\r\n\r\n');
fprintf(fid, '<!-- 輸入資料從哪裡來 → 經過哪些處理 → 輸出什麼 -->\r\n\r\n');
fprintf(fid, '## Module Breakdown\r\n\r\n');
fprintf(fid, '| File | Purpose | Inputs | Outputs |\r\n');
fprintf(fid, '|------|---------|--------|----------|\r\n');
fprintf(fid, '| `main.m` | Pipeline 主入口 | - | - |\r\n\r\n');
fprintf(fid, '## Design Decisions\r\n\r\n');
fprintf(fid, '<!-- 為什麼這樣設計？考慮過哪些替代方案？ -->\r\n\r\n');
fprintf(fid, '## CI/CD\r\n\r\n');
fprintf(fid, '<!-- buildfile.m 的 task 結構說明（由 matlab-test-execution skill 使用）-->\r\n');
fclose(fid);

% ── api.md ──
api_path = fullfile(project_path, 'docs', 'api.md');
fid = fopen(api_path, 'w', 'n', 'UTF-8');
fprintf(fid, '# API Reference — %s\r\n\r\n', project_name);
fprintf(fid, '<!-- 填入時機：每次新增或修改 src\\ 函數後（由 Docs Update Prompt 提示）-->\r\n\r\n');
fprintf(fid, '<!-- 格式範例：\r\n');
fprintf(fid, '## `function_name`\r\n');
fprintf(fid, '**Purpose**: 一句話說明\r\n\r\n');
fprintf(fid, '**Signature**:\r\n');
fprintf(fid, '```matlab\r\n');
fprintf(fid, '[output1] = function_name(input1, opts)\r\n');
fprintf(fid, '```\r\n\r\n');
fprintf(fid, '**Inputs**:\r\n');
fprintf(fid, '| Param | Type | Description |\r\n');
fprintf(fid, '|-------|------|-------------|\r\n\r\n');
fprintf(fid, '**Outputs**:\r\n');
fprintf(fid, '| Param | Type | Description |\r\n');
fprintf(fid, '|-------|------|-------------|\r\n');
fprintf(fid, '-->\r\n');
fclose(fid);

% ── experiments.md ──
exp_path = fullfile(project_path, 'docs', 'experiments.md');
fid = fopen(exp_path, 'w', 'n', 'UTF-8');
fprintf(fid, '# Experiment Log — %s\r\n\r\n', project_name);
fprintf(fid, '<!-- 填入時機：每次有具體數字的實驗跑完（由 Docs Update Prompt 提示）-->\r\n\r\n');
fprintf(fid, '<!-- 格式範例：\r\n');
fprintf(fid, '## Experiment: <簡短描述>\r\n');
fprintf(fid, '- **Date**: YYYY-MM-DD\r\n');
fprintf(fid, '- **Hypothesis**: 這次改動預期改善什麼\r\n');
fprintf(fid, '- **Config**: kernel=RBF, C=1.0 ...\r\n');
fprintf(fid, '- **Result**: F1=0.82, Accuracy=0.85\r\n');
fprintf(fid, '- **Conclusion**: 未達目標，原因...\r\n');
fprintf(fid, '- **Next**: 下次要試什麼\r\n');
fprintf(fid, '-->\r\n');
fclose(fid);

fprintf('[init_project] docs\\ stub 文件已生成（architecture.md / api.md / experiments.md）。\n');

%% ── 8. 生成 README.md 骨架 ───────────────────────────────────
%
% README.md 是跨 session 的唯一記憶載體。
% Claude 每次進入 EXISTING PROJECT mode 都必須先讀這個檔案，
% 從 Pipeline Overview 的 [x]/[ ] 找到上次中斷點，
% 從 Notes 取得當前狀態。
%
% Files 表格預設列出 main.m 和 buildfile.m，
% 後續新增的 src/*.m 和 tests/*Test.m 由開發過程中補充。

readme_path = fullfile(project_path, 'README.md');
fid = fopen(readme_path, 'w', 'n', 'UTF-8');

fprintf(fid, '# %s\r\n\r\n', project_name);
fprintf(fid, '- **Created**       : %s\r\n', datestr(now, 'yyyy-mm-dd'));
fprintf(fid, '- **Last Modified** : %s\r\n', datestr(now, 'yyyy-mm-dd'));
fprintf(fid, '- **Status**        : active\r\n');
fprintf(fid, '- **Description**   : %s\r\n\r\n', project_desc);

fprintf(fid, '## Context\r\n\r\n');
fprintf(fid, '%s\r\n\r\n', context_text);

fprintf(fid, '## Pipeline Overview\r\n\r\n');
fprintf(fid, '<!-- [x] 已完成，[ ] 待完成 -->\r\n');
fprintf(fid, '- [ ] 1. \r\n');
fprintf(fid, '- [ ] 2. \r\n');
fprintf(fid, '- [ ] 3. \r\n\r\n');

fprintf(fid, '## Files\r\n\r\n');
fprintf(fid, '| File | Purpose |\r\n');
fprintf(fid, '|------|---------|\r\n');
fprintf(fid, '| `main.m`      | Pipeline 主程式入口 |\r\n');
fprintf(fid, '| `buildfile.m` | buildtool CI 設定（matlab-test-execution）|\r\n\r\n');

fprintf(fid, '## Dependencies\r\n\r\n');
fprintf(fid, '- MATLAB Toolboxes : \r\n');
fprintf(fid, '- External data    : \r\n');
fprintf(fid, '- Shared functions : \r\n\r\n');

fprintf(fid, '## Notes\r\n\r\n');
fprintf(fid, '<!-- 每次 session 結束前更新：當前進度、已知問題、下一步行動 -->\r\n');

fclose(fid);
fprintf('[init_project] README.md 已生成。\n');

%% ── 9. 載入 _shared\ 路徑 ────────────────────────────────────
%
% 讓新 project 一開始就能呼叫所有 shared 工具函數，
% 也讓 matlab-skills 生成的函數在移至 _shared\ 後，
% 不需要手動 addpath 就能被其他 project 使用。

shared_dir = fullfile(WORKSPACE_ROOT, '_shared');
if exist(shared_dir, 'dir')
    addpath(genpath(shared_dir));
    fprintf('[init_project] _shared\\ 已加入 path。\n');
end

%% ── 9. 切換至新 project 目錄 ─────────────────────────────────
%
% 結束時 pwd = project root。
% 無論後續是 matlab-skills 的 skill 寫檔，
% 還是 buildtool / runtests 執行，都以這個目錄為基準。

cd(project_path);

%% ── 10. 輸出初始化摘要 ───────────────────────────────────────

fprintf('\n[init_project] ✓ Project 初始化完成\n');
fprintf('  Project      : %s\n',   project_name);
fprintf('  Path         : %s\n',   project_path);
fprintf('  Working dir  : %s\n\n', pwd);
fprintf('[init_project] 目錄結構：\n');
fprintf('  src\\           ← 所有 .m 函數（matlab-skills 各 skill 產出）\n');
fprintf('  src\\_backups\\ ← 結構性改寫備份\n');
fprintf('  tests\\         ← *Test.m 測試類別（matlab-test-creator）\n');
fprintf('  data\\          ← 輸入資料（.gitkeep 已建）\n');
fprintf('  output\\        ← 時間戳命名的輸出產物（.gitkeep 已建）\n');
fprintf('  buildfile.m    ← buildtool 入口（matlab-test-execution）\n');
fprintf('  README.md      ← 跨 session 狀態記錄（每次進來必讀）\n\n');
fprintf('[init_project] 下一步：填寫 README.md 的 Pipeline Overview 和 Dependencies。\n');
