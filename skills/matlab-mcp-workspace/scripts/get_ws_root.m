function root = get_ws_root()
%% get_ws_root — 動態定位 Workspace Root 路徑
% ============================================================
% VERSION  : 1.0.0 | 2025-03-27
% PURPOSE  : 從當前目錄（pwd）往上搜尋父目錄，找到含有
%            ws_config.m 標記檔的目錄，即為 workspace root。
%            設計給 project src\ 內的使用者程式碼使用，
%            讓他們不需要 hardcode workspace 路徑。
% ------------------------------------------------------------
% INPUTS   : （無）
% OUTPUTS
%   root   (char, 1×N)  - Workspace root 的絕對路徑字串
%                         例如 'D:\_self-dev\matlab-mcp-working-folder'
%
% EXAMPLE
%   % 在 project 的 src\train_classifier.m 中：
%   WS = get_ws_root();
%   addpath(fullfile(WS, '_shared', 'math_utils'));
%   shared_data = fullfile(WS, '_shared', 'data_io', 'io_load_mat_batch.m');
%
% DEPS     : Toolboxes: 無（base MATLAB only）
%            Shared fns: 無
%
% NOTES
%   - 前提：startup_workspace.m 已在此 session 執行過，
%     亦即 scripts\ 目錄已在 MATLAB path 上，否則本函數
%     本身就不會被找到（這是正確的失敗模式，不是 bug）。
%   - 搜尋深度上限為 10 層，防止在根目錄不存在 ws_config.m
%     的情況下無限迴圈。
%   - 若找不到 ws_config.m 會丟出有意義的錯誤訊息，
%     而不是靜默地回傳空字串或錯誤路徑。
% ============================================================

MAX_DEPTH  = 10;    % 搜尋深度上限：防止在惡化狀態下無限往上走
current    = pwd;   % 從當前工作目錄開始往上找

for depth = 1:MAX_DEPTH

    marker = fullfile(current, 'ws_config.m');

    if exist(marker, 'file')
        % 找到了。回傳這個目錄就是 workspace root。
        root = current;
        return;
    end

    % 往上一層：fileparts 在到達檔案系統根目錄時，
    % parent 會等於 current（例如 'C:\' 的 parent 還是 'C:\'）
    parent = fileparts(current);

    if strcmp(parent, current)
        % 已到檔案系統根目錄，找不到標記檔 → 中止搜尋
        break;
    end

    current = parent;

end

% ── 找不到的錯誤訊息設計原則：告訴使用者「怎麼修」，而不只是「壞了」 ──
error(['[get_ws_root] 找不到 ws_config.m。\n', ...
       '搜尋路徑：%s\n\n', ...
       '可能原因：\n', ...
       '  1. startup_workspace.m 尚未在此 session 執行 → 請先執行它\n', ...
       '  2. ws_config.m 被移動或刪除 → 請重新放回 workspace root\n', ...
       '  3. 當前目錄不在任何 workspace 的子目錄下\n'], pwd);

end
