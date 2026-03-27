%% list_workspace.m — Workspace 狀態總覽
% ============================================================
% VERSION  : 2.0.0 | 2025-03-27
% PURPOSE  : 列出 workspace 中所有 projects、temp sessions 及
%            archive 的狀態。從各 project 的 README.md 讀取
%            Status 和 Description，讓 Claude 在跨 session 繼續
%            工作前，能快速掌握完整 workspace 狀態。
%
% USAGE    : run('<WORKSPACE_ROOT>\scripts\list_workspace.m')
%            或在任意 project 子目錄中直接 run，腳本自我定位。
%
% OUTPUT   : 格式化文字輸出至 MATLAB Command Window
% ============================================================

%% ── 1. 自我定位 workspace root ───────────────────────────────

scripts_dir    = fileparts(mfilename('fullpath'));
WORKSPACE_ROOT = fileparts(scripts_dir);

%% ── 2. 工具：從 README.md 讀取指定欄位 ──────────────────────
%
% 用 regexp 從 README 的 Markdown 格式中提取欄位值。
% 若 README 不存在或欄位缺失，回傳有意義的 fallback 字串，
% 而不是空白或 error，讓顯示永遠有輸出。

    function val = read_readme(readme_path, pattern, fallback)
        if nargin < 3, fallback = '(未設定)'; end
        if ~exist(readme_path, 'file')
            val = '(無 README)';
            return;
        end
        fid = fopen(readme_path, 'r', 'n', 'UTF-8');
        if fid == -1
            val = '(無法讀取)';
            return;
        end
        content = fread(fid, '*char')';
        fclose(fid);
        tok = regexp(content, pattern, 'tokens', 'once');
        if isempty(tok) || isempty(tok{1})
            val = fallback;
        else
            val = strtrim(tok{1});
        end
    end

%% ── 3. 視覺分隔符與標題 ──────────────────────────────────────

SEP = repmat('─', 1, 76);
NOW = now;

fprintf('\n%s\n', SEP);
fprintf('  MATLAB MCP Workspace — %s\n', datestr(NOW, 'yyyy-mm-dd HH:MM:SS'));
fprintf('  Root: %s\n', WORKSPACE_ROOT);
fprintf('%s\n', SEP);

%% ── 4. PROJECTS ──────────────────────────────────────────────

proj_dir = fullfile(WORKSPACE_ROOT, 'projects');
fprintf('\n  PROJECTS\n  %s\n', repmat('·', 1, 60));

if ~exist(proj_dir, 'dir')
    fprintf('  (projects\\ 目錄不存在)\n');
else
    entries = dir(proj_dir);
    % 過濾掉非目錄項目和 . / .. 等系統目錄
    entries = entries([entries.isdir] & ~startsWith({entries.name}, '.'));

    if isempty(entries)
        fprintf('  (尚無 project)\n');
    else
        for i = 1:length(entries)
            nm     = entries(i).name;
            readme = fullfile(proj_dir, nm, 'README.md');

            % 讀取 README 中的兩個關鍵欄位
            status = read_readme(readme, '\*\*Status\*\*\s*:\s*([^\r\n]+)', 'unknown');
            desc   = read_readme(readme, '\*\*Description\*\*\s*:\s*([^\r\n]+)', '(無描述)');

            % 截斷過長的 description，保持輸出整齊
            if length(desc) > 40
                desc = [desc(1:37), '...'];
            end

            % 計算 project 存在天數
            age_days = floor(NOW - entries(i).datenum);

            % 根據 status 加上視覺標記，方便快速掃描
            switch lower(strtrim(status))
                case 'active',    badge = '● active   ';
                case 'completed', badge = '✓ completed';
                case 'archived',  badge = '▲ archived ';
                otherwise,        badge = '? unknown  ';
            end

            fprintf('  [%s]  %-42s  %-40s  (%dd)\n', ...
                    badge, nm, desc, age_days);
        end
    end
end

%% ── 5. TEMP SESSIONS ─────────────────────────────────────────
%
% 超過 14 天的 temp session 標記為清除候選，
% 這個門檻來自 references/01-workspace-structure.md 的約定

temp_dir = fullfile(WORKSPACE_ROOT, '_temp');
fprintf('\n  TEMP SESSIONS  (> 14 天標記為清除候選)\n  %s\n', repmat('·', 1, 60));

if ~exist(temp_dir, 'dir')
    fprintf('  (_temp\\ 目錄不存在)\n');
else
    entries = dir(temp_dir);
    entries = entries([entries.isdir] & ~startsWith({entries.name}, '.'));

    if isempty(entries)
        fprintf('  (無 temp session)\n');
    else
        for i = 1:length(entries)
            age_days = NOW - entries(i).datenum;

            % 14 天閾值：超過的加上明顯標記，讓人一眼看到需要清理的項目
            if age_days > 14
                flag = '  ← 清除候選';
            else
                flag = '';
            end

            fprintf('  %-50s  %.0f 天%s\n', entries(i).name, floor(age_days), flag);
        end
    end
end

%% ── 6. ARCHIVE ───────────────────────────────────────────────

arc_dir = fullfile(WORKSPACE_ROOT, '_archive');
fprintf('\n  ARCHIVE\n  %s\n', repmat('·', 1, 60));

if ~exist(arc_dir, 'dir')
    fprintf('  (_archive\\ 目錄不存在)\n');
else
    entries = dir(arc_dir);
    entries = entries([entries.isdir] & ~startsWith({entries.name}, '.'));
    fprintf('  已封存 %d 個 project\n', length(entries));

    % 只顯示名稱，不讀 README（archive 視為唯讀，不需要詳細狀態）
    for i = 1:length(entries)
        fprintf('  ▲ %s\n', entries(i).name);
    end
end

%% ── 7. _SHARED UTILITIES ─────────────────────────────────────

shared_dir = fullfile(WORKSPACE_ROOT, '_shared');
fprintf('\n  _SHARED UTILITIES\n  %s\n', repmat('·', 1, 60));

if ~exist(shared_dir, 'dir')
    fprintf('  (_shared\\ 目錄不存在)\n');
else
    m_files = dir(fullfile(shared_dir, '**', '*.m'));
    fprintf('  %d 個工具函數可用\n', length(m_files));
    fprintf('  詳細清單見 _shared\\README.md\n');
end

%% ── 8. 底部摘要 ──────────────────────────────────────────────

fprintf('\n%s\n', SEP);
fprintf('  當前工作目錄：%s\n', pwd);
fprintf('%s\n\n', SEP);
