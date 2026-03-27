%% startup_workspace.m — Session 初始化腳本
% ============================================================
% VERSION  : 2.0.0 | 2025-03-27
% PURPOSE  : 每次 Claude session 開始時執行。
%            完成三件事：
%            (1) 動態定位 workspace root（無 hardcode 路徑）
%            (2) 將 _shared\ 和 scripts\ 加入 MATLAB path
%            (3) 在 workspace root 維護 startup.m，
%                確保 MATLAB 重啟後 path 自動恢復
%
% USAGE    : run('<WORKSPACE_ROOT>\scripts\startup_workspace.m')
%            ← 這是唯一需要寫路徑的地方；往後所有腳本自動定位
%
% DESIGN NOTE — 為什麼不需要 hardcode？
%   本腳本自己就在 scripts\ 底下。
%   mfilename('fullpath') 回傳腳本的絕對路徑（與 pwd 無關），
%   因此不管你從哪個目錄 run 它，它都知道自己在哪裡，
%   進而推算出 workspace root = fileparts(fileparts(自己))。
%   換機器、換磁碟、改 workspace 位置，這段邏輯永遠成立。
% ============================================================

%% ── 0. Bootstrap：取得腳本自身位置，推算 workspace root ─────
%
% mfilename('fullpath') 的好處：不管 pwd 是哪裡，
% 它都回傳「這個 .m 檔案本身」的完整路徑。
% 這是讓腳本能從任意目錄被 run 的關鍵。

scripts_dir    = fileparts(mfilename('fullpath'));   % → ..\scripts
WORKSPACE_ROOT = fileparts(scripts_dir);            % → ..\（workspace root）

%% ── 1. 立刻把 scripts\ 加進 path ────────────────────────────
%
% 這樣做之後，get_ws_root.m 等工具函數就可以被其他地方呼叫了。
% 順序很重要：先加 scripts\，後面才能用 get_ws_root()。

addpath(scripts_dir);

%% ── 2. 確認 ws_config.m 存在（workspace 完整性檢查）─────────
%
% ws_config.m 是 workspace 的識別標記。如果它不見了，
% 代表 workspace 結構可能損壞，此時直接警告而非靜默繼續。

marker = fullfile(WORKSPACE_ROOT, 'ws_config.m');
if ~exist(marker, 'file')
    warning(['[startup_workspace] 找不到 ws_config.m。\n', ...
             '路徑：%s\n', ...
             '請確認 workspace root 是否正確，或重新放回 ws_config.m。'], ...
             WORKSPACE_ROOT);
    % 即使標記不在，仍繼續執行 addpath，讓 session 至少能部分運作
end

%% ── 3. 將 _shared\ 加入 path（recursive，含所有子目錄）────────
%
% genpath 會遞迴展開所有子目錄，因此 livestock\、image_processing\ 等
% 子分類的函數都能被直接呼叫，不需要個別 addpath。

shared_dir = fullfile(WORKSPACE_ROOT, '_shared');
if exist(shared_dir, 'dir')
    addpath(genpath(shared_dir));
    fprintf('[startup_workspace] _shared\ 已加入 path。\n');
else
    % _shared\ 不存在不是 fatal error，只是提醒
    % 新 workspace 第一次跑可能還沒有 _shared\
    warning('[startup_workspace] _shared\ 目錄不存在，略過 addpath。');
end

%% ── 4. 維護 startup.m（解決 MATLAB 重啟後 path 消失的問題）───
%
% MATLAB 啟動時會自動執行 userpath 下的 startup.m。
% 我們把 workspace 的 path 設定寫進 workspace root 的 startup.m，
% 讓 MATLAB 每次冷啟動都自動恢復，不需要手動重跑。
%
% 注意：startup.m 是由本腳本「自動生成維護」的，
% 使用者不應手動編輯它。要改 path 邏輯，改本腳本即可。

startup_path = fullfile(WORKSPACE_ROOT, 'startup.m');

% 用 sprintf 動態組出 startup.m 的內容，路徑來自執行期的 WORKSPACE_ROOT，
% 這樣即使 workspace 被搬移，只要重跑一次本腳本，startup.m 就會更新。
startup_content = sprintf([ ...
    '%% startup.m — 由 startup_workspace.m 自動生成，請勿手動修改\n', ...
    '%% 作用：MATLAB 重啟後自動恢復 workspace path\n', ...
    '%% 最後更新：%s\n\n', ...
    'WORKSPACE_ROOT = ''%s'';\n\n', ...
    '%% 將 scripts\ 加入 path（讓 get_ws_root 等工具可被呼叫）\n', ...
    'addpath(fullfile(WORKSPACE_ROOT, ''scripts''));\n\n', ...
    '%% 將 _shared\ 及所有子目錄加入 path\n', ...
    'shared_dir = fullfile(WORKSPACE_ROOT, ''_shared'');\n', ...
    'if exist(shared_dir, ''dir'')\n', ...
    '    addpath(genpath(shared_dir));\n', ...
    'end\n\n', ...
    'fprintf(''[startup.m] Workspace path 已恢復：%%s\\n'', WORKSPACE_ROOT);\n' ...
], datestr(now, 'yyyy-mm-dd HH:MM'), WORKSPACE_ROOT);

fid = fopen(startup_path, 'w', 'n', 'UTF-8');
if fid == -1
    % 寫入失敗通常是權限問題，不是 fatal，但要明確警告
    warning('[startup_workspace] 無法寫入 startup.m，請確認目錄寫入權限。\n路徑：%s', startup_path);
else
    fprintf(fid, '%s', startup_content);
    fclose(fid);
end

%% ── 5. 輸出狀態摘要 ──────────────────────────────────────────

fprintf('\n[startup_workspace] ✓ Session 初始化完成\n');
fprintf('  Workspace root : %s\n', WORKSPACE_ROOT);
fprintf('  Current pwd    : %s\n', pwd);
fprintf('  startup.m      : %s\n\n', startup_path);
