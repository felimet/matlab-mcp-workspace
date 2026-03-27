%% ws_config.m — Workspace Root Marker File
% ============================================================
% VERSION  : 1.0.0 | 初始建立時自動生成
% PURPOSE  : 標記 workspace 根目錄的錨點檔案。
%            本身不含任何可執行邏輯；所有腳本透過
%            搜尋本檔案的位置來動態定位 workspace root，
%            因此整個 workspace 可以放在任意路徑而不需要
%            在任何腳本或文件中寫死絕對路徑。
%
% IMPORTANT: 請勿移動、重命名或刪除此檔案。
%            若此檔案消失，get_ws_root() 和所有依賴它的
%            使用者程式碼將無法定位 workspace root。
%
% HOW IT WORKS:
%   1. scripts\ 內的腳本直接用 mfilename('fullpath') 推算
%      自身位置，fileparts(fileparts(...)) 就是 root，
%      完全不需要讀這個檔案。
%   2. project src\ 內的使用者程式碼呼叫 get_ws_root()，
%      該函數往上搜尋父目錄，直到找到本檔案為止。
%
% 換句話說：
%   scripts\ 的人靠「我在哪裡」找到 root。
%   src\ 的人靠「這個標記在哪裡」找到 root。
%   兩條路，結果一樣，都不用 hardcode。
%
% INITIALIZED: <YYYY-MM-DD>（由 startup_workspace.m 首次執行時記錄）
% WORKSPACE  : <path>（資訊性記錄，非功能性；實際路徑以執行期動態取得為準）
% ============================================================
