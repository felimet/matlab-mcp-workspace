# 08 — Project Docs（Lookup）

> 完整說明見 `docs/08-project-docs.md`

---

## docs\ 職責表

```
projects\YYYYMMDD_<slug>\
├── README.md            入口：狀態、pipeline 進度、快速摘要
└── docs\
    ├── architecture.md  系統設計：結構、資料流、設計決策
    ├── api.md           函數介面：所有 src\ 函數簽名與說明
    └── experiments.md   實驗紀錄：參數配置、結果、結論
```

| 文件 | 用途 | Claude 讀取時機 |
|------|------|----------------|
| `README.md` | 跨 session 狀態板 | 每次進入 EXISTING PROJECT |
| `architecture.md` | 設計邏輯 + 資料流 | 使用者問到架構/設計時 |
| `api.md` | `src\` 函數介面索引 | 使用者問到函數用法時 |
| `experiments.md` | 實驗參數 + 結果 | 使用者問到實驗結果時 |

---

## README 關鍵欄位

| 欄位 | Claude 用途 |
|------|-------------|
| `Status` | 判斷是否繼續開發 |
| `Pipeline Overview` | 找中斷點（`[x]`→`[ ]`）|
| `Notes` | Resuming 摘要來源 |

Notes 最少三維度：上次做到哪、卡在什麼、下次做什麼。

---

## Docs Update Prompt 觸發對照表

| 改動類型 | 提示更新 |
|----------|----------|
| `src\` 新增 `.m` 函數 | `docs\api.md`（補函數說明）|
| 函數**簽名改變** | `docs\api.md`（更新介面）|
| 演算法邏輯替換 | `docs\architecture.md`（設計決策）|
| Pipeline 步驟完成 | `docs\experiments.md` + `README.md Notes` |
| `buildfile.m` 結構改動 | `docs\architecture.md`（CI/CD）|
| `_shared\` 新增/修改 | `_shared\README.md`（更新 index）|
| `tests\` 新增測試類別 | `docs\api.md`（測試覆蓋說明）|

不觸發：小幅 bug fix、`_temp\` 改動、無實質影響的格式調整。

---

## Prompt 輸出格式

```
---
> [!NOTE] **[Docs Update Prompt]**
> 本次改動建議同步更新以下文件：
> - `docs\api.md` — 新增 `<function_name>` 函數說明
> - `docs\architecture.md` — <簡述改動點>
>
> 確認後說「更新文件」，我會依序協助你補。如不需要，忽略即可。
```

### 行為規則

- 只列真正受影響的項目
- 說明要具體（函數名、改了什麼）
- 一定在回應末端
- `_temp\` 不觸發

---

## 更新節奏表

| 文件 | 適合更新時機 |
|------|-------------|
| `README.md Notes` | session 結束前；里程碑 |
| `architecture.md` | 設計重大改變；演算法替換 |
| `api.md` | 新增函數；簽名改變；函數廢棄 |
| `experiments.md` | 有具體數字的實驗跑完 |

判斷標準：「三個月後第一次看的人，需要知道嗎？」

---

## 不需要 docs\ 的情況

| 情境 | 原因 |
|------|------|
| `_temp\` session | 短生命週期 |
| 單一函數小 project（< 3 `.m`）| README Notes 足夠 |
| 純測試/一次性驗算 | 無長期維護需求 |

## Experiment 記錄格式

```markdown
## Exp-NNN: <標題>
- **Date**: YYYY-MM-DD
- **Hypothesis**: <假設>
- **Config**: <參數配置>
- **Result**: <數值結果>
- **Conclusion**: <結論>
- **Next**: <下一步行動>
```

`Next` 是最重要欄位 — 沒有它，下次 session 不知道如何繼續。
