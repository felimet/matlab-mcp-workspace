%% workspace_health.m — Workspace 健康狀態檢查
% ============================================================
% VERSION  : 2.0.0 | 2025-03-27
% PURPOSE  : 對 workspace 執行 6 項結構性檢查，標記需要處理的
%            問題。包含：過期 temp、workspace root 汙染、
%            缺少 README 的 project、備份堆積、output 膨脹、
%            以及 _shared\ 函數缺少標準文檔。
%            設計為「零假陽性」——每個標記出來的問題都值得關注，
%            沒有沒意義的警告雜訊。
%
% WHEN TO USE：
%   - 定期清理時
%   - 封存 project 前
%   - 感覺 workspace 開始亂的時候
%
% OUTPUT   : 格式化文字報告至 MATLAB Command Window
% ============================================================

%% ── 1. 自我定位 workspace root ───────────────────────────────

scripts_dir    = fileparts(mfilename('fullpath'));
WORKSPACE_ROOT = fileparts(scripts_dir);

%% ── 2. 初始化計數器與視覺元素 ───────────────────────────────

NOW    = now;
SEP    = repmat('─', 1, 76);
issues = 0;    % 問題總數，健康時應為 0

fprintf('\n%s\n', SEP);
fprintf('  Workspace Health Check — %s\n', datestr(NOW, 'yyyy-mm-dd HH:MM'));
fprintf('  Root: %s\n', WORKSPACE_ROOT);
fprintf('%s\n\n', SEP);

%% ── 3. 檢查一：Temp Session 是否過期（> 14 天）──────────────
%
% 14 天是 temp 生命週期的上限（見 references/01-workspace-structure.md）。
% 超過的不代表一定要刪，而是提醒「你得做個決定：升級還是清除」。

fprintf('[1] 過期 Temp Sessions（> 14 天）\n');
temp_dir = fullfile(WORKSPACE_ROOT, '_temp');

if ~exist(temp_dir, 'dir')
    fprintf('    (略過：_temp\\ 不存在)\n\n');
else
    entries  = dir(temp_dir);
    entries  = entries([entries.isdir] & ~startsWith({entries.name}, '.'));
    expired  = entries(([entries.datenum] < NOW - 14));

    if isempty(expired)
        fprintf('    ✓ 無過期 temp\n\n');
    else
        issues = issues + length(expired);
        for i = 1:length(expired)
            age = floor(NOW - expired(i).datenum);
            fprintf('    ✗ %-50s (%d 天)\n', expired(i).name, age);
        end
        fprintf('    → 處理方式：確認後刪除；或執行 upgrade_temp.m 升級為 project\n\n');
    end
end

%% ── 4. 檢查二：Workspace Root 直接汙染 ─────────────────────
%
% Workspace root 不應有任何使用者 .m 檔案（只允許 startup.m 和 ws_config.m）。
% 如果有其他 .m 在 root，代表某次 session 沒有正確分類工作路徑。

fprintf('[2] Workspace Root 中的孤立 .m 檔案\n');
root_m = dir(fullfile(WORKSPACE_ROOT, '*.m'));

% 排除合法的系統檔案
system_files = {'startup.m', 'ws_config.m'};
root_m = root_m(~ismember({root_m.name}, system_files));

if isempty(root_m)
    fprintf('    ✓ Root 目錄乾淨\n\n');
else
    issues = issues + length(root_m);
    for i = 1:length(root_m)
        fprintf('    ✗ %s\n', root_m(i).name);
    end
    fprintf('    → 處理方式：移至適當的 project\\src\\ 或 _temp\\\n\n');
end

%% ── 5. 檢查三：Projects 缺少 README.md ──────────────────────
%
% README.md 是跨 session 的記憶載體。沒有它，Claude 下次進來就是從零開始，
% 等同於讓每次對話都重新解釋一遍「我在做什麼」。

fprintf('[3] Projects 缺少 README.md\n');
proj_dir = fullfile(WORKSPACE_ROOT, 'projects');

if ~exist(proj_dir, 'dir')
    fprintf('    (略過：projects\\ 不存在)\n\n');
else
    entries   = dir(proj_dir);
    entries   = entries([entries.isdir] & ~startsWith({entries.name}, '.'));
    no_readme = {};

    for i = 1:length(entries)
        if ~exist(fullfile(proj_dir, entries(i).name, 'README.md'), 'file')
            no_readme{end+1} = entries(i).name;  %#ok<AGROW>
        end
    end

    if isempty(no_readme)
        fprintf('    ✓ 所有 projects 均有 README.md\n\n');
    else
        issues = issues + length(no_readme);
        for i = 1:length(no_readme)
            fprintf('    ✗ %s\n', no_readme{i});
        end
        fprintf('    → 處理方式：執行 init_project.m 補建，或手動建立 README.md\n\n');
    end
end

%% ── 6. 檢查四：備份堆積（每個 project > 5 份 backup）────────
%
% 超過 5 份備份通常代表長期沒有清理，或大量頻繁的結構性改寫。
% 這不是 fatal error，但值得回頭看看是否有不再需要的舊備份。

fprintf('[4] 備份堆積（每個 project > 5 份 _backups\\）\n');

if ~exist(proj_dir, 'dir')
    fprintf('    (略過：projects\\ 不存在)\n\n');
else
    entries  = dir(proj_dir);
    entries  = entries([entries.isdir] & ~startsWith({entries.name}, '.'));
    any_heavy = false;

    for i = 1:length(entries)
        bak_dir = fullfile(proj_dir, entries(i).name, 'src', '_backups');
        if exist(bak_dir, 'dir')
            baks = dir(fullfile(bak_dir, '*.m'));
            if length(baks) > 5
                fprintf('    ⚠ %-45s (%d 份備份)\n', entries(i).name, length(baks));
                issues    = issues + 1;
                any_heavy = true;
            end
        end
    end

    if ~any_heavy
        fprintf('    ✓ 無備份堆積\n');
    else
        fprintf('    → 處理方式：保留最後 3 份，刪除較舊的備份\n');
    end
    fprintf('\n');
end

%% ── 7. 檢查五：Output 目錄膨脹（> 50 個檔案）───────────────
%
% Output 目錄不進 Git，但磁碟空間是真實的。
% 50 個檔案是提醒閾值，不是硬性限制。

fprintf('[5] Output 目錄膨脹（> 50 個檔案）\n');

if ~exist(proj_dir, 'dir')
    fprintf('    (略過：projects\\ 不存在)\n\n');
else
    entries   = dir(proj_dir);
    entries   = entries([entries.isdir] & ~startsWith({entries.name}, '.'));
    any_heavy = false;

    for i = 1:length(entries)
        out_dir = fullfile(proj_dir, entries(i).name, 'output');
        if exist(out_dir, 'dir')
            % dir 包含 . 和 ..，所以要過濾掉目錄項目
            out_files = dir(out_dir);
            out_files = out_files(~[out_files.isdir]);
            if length(out_files) > 50
                fprintf('    ⚠ %-45s (%d 個檔案)\n', entries(i).name, length(out_files));
                issues    = issues + 1;
                any_heavy = true;
            end
        end
    end

    if ~any_heavy
        fprintf('    ✓ 無膨脹的 output 目錄\n');
    else
        fprintf('    → 處理方式：歸檔或刪除不再需要的舊版輸出\n');
    end
    fprintf('\n');
end

%% ── 8. 檢查六：_shared\ 函數缺少標準文檔 ───────────────────
%
% _shared\ 函數的文檔是 Claude 判斷可否複用的唯一依據。
% 沒有文檔 = Claude 必須讀函數本體才能判斷，浪費 context，
% 且無法確保理解正確。
%
% 判斷標準：函數開頭 300 字元內必須出現 'FUNCTION' 和 'PURPOSE'
% 這兩個關鍵字（來自標準文檔格式的必填欄位）。

fprintf('[6] _shared\\ 函數缺少標準文檔（FUNCTION / PURPOSE 欄位）\n');
shared_dir = fullfile(WORKSPACE_ROOT, '_shared');

if ~exist(shared_dir, 'dir')
    fprintf('    (略過：_shared\\ 不存在)\n\n');
else
    m_files = dir(fullfile(shared_dir, '**', '*.m'));
    no_doc  = {};

    for i = 1:length(m_files)
        filepath = fullfile(m_files(i).folder, m_files(i).name);
        fid      = fopen(filepath, 'r', 'n', 'UTF-8');
        if fid == -1, continue; end

        % 只讀前 300 字元：標準文檔必須在函數開頭，讀太多沒意義
        header = fread(fid, 300, '*char')';
        fclose(fid);

        % 兩個關鍵字都要有，少一個就算缺少文檔
        if ~contains(header, 'FUNCTION') || ~contains(header, 'PURPOSE')
            no_doc{end+1} = m_files(i).name;  %#ok<AGROW>
        end
    end

    if isempty(no_doc)
        fprintf('    ✓ 所有 shared 函數均有標準文檔\n\n');
    else
        issues = issues + length(no_doc);
        for i = 1:length(no_doc)
            fprintf('    ✗ %s\n', no_doc{i});
        end
        fprintf('    → 處理方式：補齊文檔（格式見 references/05-shared-utilities.md）\n\n');
    end
end

%% ── 9. 總結 ──────────────────────────────────────────────────

fprintf('%s\n', SEP);

if issues == 0
    fprintf('  ✓ Workspace 健康，無任何問題。\n');
else
    fprintf('  ⚠ 共發現 %d 個問題，請逐一處理。\n', issues);
end

fprintf('  當前工作目錄：%s\n', pwd);
fprintf('%s\n\n', SEP);
