%% upgrade_temp.m — Temp Session 升級為正式 Project
% ============================================================
% VERSION  : 2.0.0 | 2025-03-27
% PURPOSE  : 將 _temp\ 下的一個 session 升級為正式 project。
%            執行 movefile、補建缺少的子目錄、生成 README.md，
%            並設好 path 和工作目錄。
%            升級是不可逆的：temp 目錄會被移走，
%            請確認 CONFIG 中的 temp_slug 填寫正確再執行。
%
% WHEN TO USE：
%   - temp session 超過 3 個 .m 檔案
%   - 使用者決定長期保留 temp 的工作成果
%   - Temp 中的函數需要被其他 project 引用（必須先升級）
%   - 任務複雜度超出「臨時測試」的定義
%
% USAGE    : 修改 CONFIG 區塊後執行。
%            腳本自我定位 workspace root，不依賴 hardcode 路徑。
% ============================================================

%% ── CONFIG ── 每次升級只需修改這四個變數 ─────────────────────

temp_slug    = '20250327_test_fft';       % 現有 temp 目錄的名稱（含日期前綴）
project_slug = 'nir_fft_analysis';        % 新 project 的 slug（不含日期，≤ 30 字元）
project_desc = 'One-sentence description of the promoted project.';
context_text = 'Context: why this was promoted from temp. What the code does.';

%% ── END CONFIG ───────────────────────────────────────────────

%% ── 1. 自我定位 workspace root ───────────────────────────────

scripts_dir    = fileparts(mfilename('fullpath'));
WORKSPACE_ROOT = fileparts(scripts_dir);

%% ── 2. 組出來源和目的地路徑 ─────────────────────────────────
%
% 升級後的 project 用「今日日期」作為前綴，而不是沿用 temp 的原始日期。
% 這樣日期代表的是「正式開始的時間」，不是「隨手測試的時間」。

today_str    = datestr(now, 'yyyymmdd');
temp_path    = fullfile(WORKSPACE_ROOT, '_temp',    temp_slug);
project_name = [today_str, '_', project_slug];
project_path = fullfile(WORKSPACE_ROOT, 'projects', project_name);

%% ── 3. 來源路徑驗證 ──────────────────────────────────────────
%
% 在執行任何不可逆操作前，先驗證輸入是否正確。
% 早期 fail（帶有清楚的錯誤訊息）遠好過執行到一半的殘破狀態。

if ~exist(temp_path, 'dir')
    error(['[upgrade_temp] 找不到 temp 目錄：%s\n', ...
           '請確認 CONFIG 中的 temp_slug 是否正確。\n', ...
           '執行 list_workspace.m 可列出所有現有 temp session。'], temp_path);
end

if exist(project_path, 'dir')
    error(['[upgrade_temp] Project 目錄已存在：%s\n', ...
           '請在 project_slug 中使用不同的識別詞。'], project_path);
end

%% ── 4. 執行升級：移動目錄 ────────────────────────────────────
%
% movefile 是原子性操作：要麼完成，要麼完全不動。
% 不使用 copyfile + rmdir 的兩步驟做法，
% 因為中間如果出錯會留下兩份資料，讓狀態更難釐清。

movefile(temp_path, project_path);
fprintf('[upgrade_temp] 已移動：\n  %s\n  → %s\n', temp_path, project_path);

%% ── 5. 補建缺少的子目錄（冪等：已存在的不重建）─────────────
%
% temp session 是扁平結構，沒有 src/data/output 子目錄。
% 升級後需要補齊，但如果因為某種原因某個目錄已存在（例如使用者自己建的），
% 不要覆蓋，直接跳過。

subdirs = {
    'src',
    fullfile('src', '_backups'),
    'data',
    'output'
};

for i = 1:length(subdirs)
    d = fullfile(project_path, subdirs{i});
    if ~exist(d, 'dir')
        mkdir(d);
        fprintf('[upgrade_temp] 建立子目錄：%s\n', subdirs{i});
    end
end

%% ── 6. 放入 .gitkeep ─────────────────────────────────────────

for keep_dir = {'data', 'output'}
    gk = fullfile(project_path, keep_dir{1}, '.gitkeep');
    if ~exist(gk, 'file')
        fid = fopen(gk, 'w');
        fclose(fid);
    end
end

%% ── 7. 生成 README.md（若已存在則保留，不覆蓋）─────────────
%
% 有些使用者可能在 temp 階段就已經建了 README.md。
% 保留它比覆蓋它更安全——蓋掉已有的筆記不可逆。

readme_path = fullfile(project_path, 'README.md');

if exist(readme_path, 'file')
    fprintf('[upgrade_temp] README.md 已存在，保留原有內容。\n');
    fprintf('[upgrade_temp] 請手動確認並更新 Status 欄位為 active。\n');
else
    fid = fopen(readme_path, 'w', 'n', 'UTF-8');
    fprintf(fid, '# %s\r\n\r\n', project_name);
    fprintf(fid, '- **Created**       : %s\r\n', today_str);
    fprintf(fid, '- **Last Modified** : %s\r\n', today_str);
    fprintf(fid, '- **Status**        : active\r\n');
    fprintf(fid, '- **Description**   : %s\r\n', project_desc);
    fprintf(fid, '- **Promoted from** : _temp\\%s\r\n\r\n', temp_slug);
    fprintf(fid, '## Context\r\n\r\n%s\r\n\r\n', context_text);
    fprintf(fid, '## Pipeline Overview\r\n\r\n');
    fprintf(fid, '- [ ] 1. \r\n- [ ] 2. \r\n\r\n');
    fprintf(fid, '## Files\r\n\r\n');
    fprintf(fid, '| File | Purpose |\r\n|------|---------|\r\n\r\n');
    fprintf(fid, '## Dependencies\r\n\r\n');
    fprintf(fid, '- MATLAB Toolboxes: \r\n- External data   : \r\n- Shared functions: \r\n\r\n');
    fprintf(fid, '## Notes\r\n\r\n');
    fprintf(fid, '<!-- 從 temp 升級而來，請補充開發背景與當前進度 -->\r\n');
    fclose(fid);
    fprintf('[upgrade_temp] README.md 已生成。\n');
end

%% ── 8. 恢復 path 並切換至新 project ─────────────────────────

shared_dir = fullfile(WORKSPACE_ROOT, '_shared');
if exist(shared_dir, 'dir')
    addpath(genpath(shared_dir));
end

cd(project_path);

%% ── 9. 輸出結果與提示 ────────────────────────────────────────

fprintf('\n[upgrade_temp] ✓ 升級完成\n');
fprintf('  Project name   : %s\n', project_name);
fprintf('  Full path      : %s\n', project_path);
fprintf('  Working dir set: %s\n\n', pwd);
fprintf('[upgrade_temp] ⚠  ACTION REQUIRED：\n');
fprintf('  README.md 的 Context、Files、Notes 欄位需要人工填寫。\n');
fprintf('  腳本無法重建 temp session 期間的開發意圖，只有你知道當時在做什麼。\n');
