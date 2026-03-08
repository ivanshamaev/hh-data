# 06 — Диаграмма слоёв данных

Ниже приведена диаграмма таблиц по слоям и потоков данных. Формат — **Mermaid**: его можно просматривать в GitHub, в VS Code (расширение Mermaid), в Cursor или сгенерировать картинку через [mermaid-cli](https://github.com/mermaid-js/mermaid-cli).

## Как запустить и посмотреть диаграмму

1. **В браузере (онлайн)**  
   Скопируйте блок кода из секции «Код диаграммы» ниже и вставьте в [Mermaid Live Editor](https://mermaid.live/) — диаграмма отрисуется сразу.

2. **В VS Code / Cursor**  
   Установите расширение «Mermaid» (или «Markdown Preview Mermaid Support»). Откройте этот файл и откройте предпросмотр Markdown (Ctrl+Shift+V / Cmd+Shift+V) — диаграмма отобразится в превью.

3. **Экспорт в PNG/SVG (mermaid-cli)**  
   Установите `@mermaid-js/mermaid-cli`, сохраните код в файл `docs/data-flow.mmd` и выполните:
   ```bash
   npx @mermaid-js/mermaid-cli -i docs/data-flow.mmd -o docs/data-flow.png
   ```
   Или используйте поддиаграмму из этого файла (см. ниже отдельный блок для `.mmd`).

4. **В GitHub**  
   В репозитории при просмотре этого `.md` файла GitHub сам рендерит Mermaid-блоки.

---

## Диаграмма: таблицы по слоям и поток данных

```mermaid
flowchart TB
    subgraph API["API HH.ru"]
        api_roles["/professional_roles"]
        api_vac["/vacancies"]
        api_detail["/vacancies/{id}"]
    end

    subgraph raw["Слой RAW (схема raw)"]
        direction TB
        raw_cat["raw.categories"]
        raw_roles["raw.roles"]
        raw_vac["raw.vacancies"]
        raw_search["raw.vacancies_search"]
        raw_loaded["raw.vacancy_details_loaded"]
        raw_detail["raw.vacancy_details"]
        raw_wide["raw.vacancy_details_wide"]
        raw_view["raw.vacancies_for_details (view)"]
    end

    subgraph dv["Слой Data Vault (схема dv)"]
        direction TB
        subgraph hubs["Хабы"]
            H_V["H_Vacancy"]
            H_A["H_Area"]
            H_E["H_Employer"]
            H_S["H_Schedule"]
            H_Em["H_Employment"]
            H_Ex["H_Experience"]
            H_B["H_BillingType"]
            H_F["H_EmploymentForm"]
            H_PR["H_ProfessionalRole"]
            H_Sk["H_Skill"]
        end
        subgraph links["Линки"]
            L_VA["L_Vacancy_Area"]
            L_VE["L_Vacancy_Employer"]
            L_VS["L_Vacancy_Schedule"]
            L_VEm["L_Vacancy_Employment"]
            L_VEx["L_Vacancy_Experience"]
            L_VB["L_Vacancy_BillingType"]
            L_VF["L_Vacancy_EmploymentForm"]
            L_VPR["L_Vacancy_ProfessionalRole"]
            L_VSk["L_Vacancy_Skill"]
        end
        subgraph sats["Спутники"]
            S_V["S_Vacancy_Details"]
            S_A["S_Area_Details"]
            S_E["S_Employer_Details"]
            S_S["S_Schedule_Details"]
            S_Em["S_Employment_Details"]
            S_Ex["S_Experience_Details"]
            S_B["S_BillingType_Details"]
            S_F["S_EmploymentForm_Details"]
            S_PR["S_ProfessionalRole_Details"]
        end
    end

    api_roles --> raw_cat
    api_roles --> raw_roles
    api_vac --> raw_vac
    api_vac --> raw_search
    api_detail --> raw_detail
    raw_detail --> raw_loaded
    raw_detail --> raw_wide
    raw_vac --> raw_view
    raw_roles --> raw_view

    raw_detail --> H_V
    raw_detail --> H_A
    raw_detail --> H_E
    raw_detail --> hubs
    hubs --> links
    raw_detail --> links
    raw_detail --> S_V
    raw_detail --> sats
```

---

## Упрощённая схема: только таблицы по слоям (без потоков)

Удобно для быстрого просмотра списка объектов по слоям.

```mermaid
flowchart LR
    subgraph raw["RAW"]
        raw_detail["vacancy_details"]
        raw_wide["vacancy_details_wide"]
        raw_vac["vacancies"]
        raw_search["vacancies_search"]
        raw_cat["categories"]
        raw_roles["roles"]
    end

    subgraph dv["Data Vault"]
        subgraph H["Hubs"]
            H1["H_Vacancy"]
            H2["H_Area, H_Employer, ..."]
        end
        subgraph L["Links"]
            L1["L_Vacancy_*"]
        end
        subgraph S["Satellites"]
            S1["S_Vacancy_Details"]
            S2["S_*_Details"]
        end
    end

    raw --> dv
```

---

## Генерация PNG/SVG (mermaid-cli)

В репозитории уже есть файл `docs/data-flow.mmd` с полной диаграммой. Сгенерировать картинку:

```bash
npx @mermaid-js/mermaid-cli -i docs/data-flow.mmd -o docs/data-flow.png
```

Для SVG замените расширение выхода на `-o docs/data-flow.svg`. Требуется установленный Node.js и (при первом запуске) загрузка пакета mermaid-cli.
