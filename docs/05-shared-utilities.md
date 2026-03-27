# 05 — Shared Utilities

> [!IMPORTANT]
> `_shared\` 是整個 workspace 維護成本最高的目錄。函數一旦被多個 project 引用，任何破壞性修改都會造成連帶影響。進行任何修改前，必須先確認影響範圍。

---

## 目錄結構與分類原則

```
_shared\
├── README.md               ← 函數總索引（Claude 讀這個決定要不要複用）
├── image_processing\       ← 影像讀寫、增強、形態學
├── data_io\                ← 批次載入、格式轉換、結果匯出
├── visualization\          ← 繪圖、圖片儲存、混淆矩陣
├── math_utils\             ← 正規化、統計、矩陣操作
└── livestock\              ← 領域特定：GEI、步態、呼吸頻率等
```

### 分類邏輯

| 函數的性質 | 放哪裡 |
|-----------|--------|
| 只有一個 project 會用到 | 放在該 project 的 `src\` |
| 多個 project 通用 | `_shared\<對應分類>\` |
| 跨 project 但強烈領域相關 | `_shared\livestock\`（或對應子目錄）|
| 通用數學 / 統計工具 | `_shared\math_utils\` |

> [!NOTE]
> 不確定未來會不會複用的函數，先放在 project 的 `src\`，等真的有第二個 project 需要它再遷移。一個函數進了 `_shared\` 就意味著你承諾維護它的相容性。

---

## 標準化文檔格式

> [!IMPORTANT]
> 每個 `_shared\` 函數頂部**必須**包含以下文檔區塊。Claude 依賴這個區塊判斷函數是否可複用，**不需要讀函數本體**。文檔必須自給自足，不能留白。

```matlab
% ============================================================
% FUNCTION : function_name
% VERSION  : 1.0.0 | YYYY-MM-DD
% PURPOSE  : 一句話描述這個函數做什麼（≤ 80 字元）
% ------------------------------------------------------------
% INPUTS
%   x       (double, M×N)  - 說明：類型、維度、值域限制
%   opts    (struct)       - 選項結構；各欄位：
%                            .threshold (double, 預設 0.5, 範圍 [0,1])
%                            .mode      ('fast'|'precise', 預設 'fast')
%
% OUTPUTS
%   result  (double, M×N)  - 說明輸出是什麼
%   mask    (logical, M×N) - 說明這個輸出的用途
%
% EXAMPLE
%   % 最小可運行範例——可直接貼入命令列執行
%   img    = imread('test.png');
%   opts   = struct('threshold', 0.3, 'mode', 'fast');
%   [r, m] = img_normalize_histogram(img, opts);
%   imshow(r);
%
% DEPS
%   Toolboxes  : Image Processing Toolbox (imhisteq)
%   Shared fns : (無 / 若有依賴則列出函數名)
%
% NOTES
%   - 已知限制（例如：輸入必須是 uint8，不支援 RGB）
%   - 效能提示（例如：M×N > 1000×1000 時速度明顯下降）
%   - CHANGELOG：v1.1.0 (2025-04-01) 新增 opts.mode 參數
% ============================================================
```

### 文檔提交前檢查清單

- [ ] `FUNCTION` 名稱與檔名完全一致
- [ ] `VERSION` 有版本號與日期
- [ ] `PURPOSE` 一句話說「做什麼」，不是「怎麼做」
- [ ] 每個 `INPUT` 有型別、維度、值域或允許值
- [ ] 每個 `OUTPUT` 有型別與用途說明
- [ ] `EXAMPLE` 可直接複製貼上執行（零前置設定）
- [ ] `DEPS` 列出所有非 base MATLAB 的依賴
- [ ] `NOTES` 包含已知限制

---

## `_shared\README.md` 格式規範

> [!IMPORTANT]
> 這是 Claude 判斷是否有可用共用函數的**第一入口**，不需要讀各函數本體。每次新增、修改或棄用函數後必須同步更新。

```markdown
# Shared Utilities — Function Index
Last updated: YYYY-MM-DD

## image_processing\
| 函數 | 版本 | 用途 | 主要輸入 | Toolbox |
|------|------|------|---------|---------|
| img_normalize_histogram.m | 1.0.0 | 直方圖正規化 | img (M×N uint8), opts | IPT |
| img_extract_silhouette.m  | 1.1.0 | 背景消除 + 輪廓提取 | img, bg_model | IPT |
| img_apply_clahe.m         | 1.0.0 | CLAHE 增強 | img, tile_size | IPT |

## data_io\
| 函數 | 版本 | 用途 | 主要輸入 | Toolbox |
|------|------|------|---------|---------|
| io_load_mat_batch.m   | 1.0.0 | 批次載入 .mat | folder, pattern | — |
| io_export_results.m   | 1.2.0 | 結構化結果匯出 | results, out_dir | — |

## visualization\
| 函數 | 版本 | 用途 | 主要輸入 | Toolbox |
|------|------|------|---------|---------|
| viz_confusion_matrix.m | 1.0.0 | 繪製 + 儲存混淆矩陣 | C, class_names, out_path | — |
| viz_save_figure.m      | 1.0.0 | 時間戳命名儲存圖片 | fig, prefix, out_dir | — |

## math_utils\
| 函數 | 版本 | 用途 | 主要輸入 | Toolbox |
|------|------|------|---------|---------|
| math_normalize_minmax.m | 1.0.0 | [0,1] min-max 正規化 | x, [min max] | — |

## livestock\
| 函數 | 版本 | 用途 | 主要輸入 | Toolbox |
|------|------|------|---------|---------|
| lv_gei_compute.m        | 1.0.0 | 從幀序列計算 GEI | frames (M×N×T) | IPT |
| lv_respiration_rate.m   | 1.0.0 | 光流法估計呼吸頻率 | region_ts, fps | CV Toolbox |

---

> [!NOTE]
> 有 ⚠️ **DEPRECATED** 標記的函數即將廢棄，請改用標記中的替代函數。
```

---

## 新增 Shared 函數工作流程

```
1. 先在 project src\ 開發並測試
        ↓
2. 確認至少 2 個 project 需要此功能
        ↓
3. 移至 _shared\<適當分類>\
        ↓
4. 補齊標準化文檔區塊（含 VERSION、CHANGELOG）
        ↓
5. 更新 _shared\README.md 對應分類的表格
        ↓
6. 在原 project 確認 addpath 後呼叫正常
        ↓
7. Git commit: feat(shared): add <function_name>
```

> [!TIP]
> 「2 個 project 都需要」是最低門檻，不是把一切都塞進 shared 的理由。判斷標準是：**換一個完全不同的資料集，這個函數還能用嗎？** 如果介面是通用的，進 shared；如果強烈依賴特定 project 的資料格式，留在 `src\`。
