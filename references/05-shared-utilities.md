# 05 — Shared Utilities（Lookup）

> 完整說明見 `docs/05-shared-utilities.md`

---

## 分類對照表

| 函數性質 | 放哪裡 |
|----------|--------|
| 只有一個 project 會用 | 該 project `src\` |
| 多個 project 通用 | `_shared\<category>\` |
| 跨 project 但強領域相關 | `_shared\livestock\`（或對應子目錄）|
| 通用數學/統計 | `_shared\math_utils\` |

**不確定是否複用 → 先放 `src\`**，等第二個 project 需要再遷移。

---

## 目錄結構

```
_shared\
├── README.md              函數總索引
├── image_processing\      影像讀寫、增強、形態學
├── data_io\               批次載入、格式轉換、結果匯出
├── visualization\         繪圖、圖片儲存、混淆矩陣
├── math_utils\            正規化、統計、矩陣操作
└── livestock\             領域特定（GEI、步態、呼吸頻率等）
```

---

## Docstring Template

```matlab
% ============================================================
% FUNCTION : function_name
% VERSION  : 1.0.0 | YYYY-MM-DD
% PURPOSE  : 一句話（≤ 80 字元）
% ------------------------------------------------------------
% INPUTS
%   x       (double, M×N)  - 說明：類型、維度、值域
%   opts    (struct)       - 選項結構：
%                            .threshold (double, 預設 0.5, [0,1])
%                            .mode      ('fast'|'precise', 預設 'fast')
%
% OUTPUTS
%   result  (double, M×N)  - 說明
%   mask    (logical, M×N) - 說明
%
% EXAMPLE
%   img    = imread('test.png');
%   opts   = struct('threshold', 0.3, 'mode', 'fast');
%   [r, m] = function_name(img, opts);
%
% DEPS
%   Toolboxes  : (列出 / 無)
%   Shared fns : (列出 / 無)
%
% NOTES
%   - 已知限制
%   - 效能提示
%   - CHANGELOG
% ============================================================
```

### Docstring Checklist

- [ ] `FUNCTION` 與檔名一致
- [ ] `VERSION` 有版本號 + 日期
- [ ] `PURPOSE` 說「做什麼」非「怎麼做」
- [ ] 每個 `INPUT`/`OUTPUT` 有型別、維度、值域
- [ ] `EXAMPLE` 可零前置直接執行
- [ ] `DEPS` 列出非 base MATLAB 依賴
- [ ] `NOTES` 含已知限制

---

## `_shared\README.md` Format

```markdown
# Shared Utilities — Function Index
Last updated: YYYY-MM-DD

## <category>\
| 函數 | 版本 | 用途 | 主要輸入 | Toolbox |
|------|------|------|---------|---------|
| name.m | 1.0.0 | 一句話 | 型別概述 | 名稱/— |
```

Deprecated 函數標記 `DEPRECATED`，附替代函數名。

---

## 新增 Shared 函數流程

```
1. project src\ 開發 + 測試
2. 確認 ≥ 2 個 project 需要
3. 移至 _shared\<category>\
4. 補齊 docstring（VERSION + CHANGELOG）
5. 更新 _shared\README.md
6. 原 project 確認 addpath 後呼叫正常
7. Git commit: feat(shared): add <function_name>
```
