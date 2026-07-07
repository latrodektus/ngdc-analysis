# Codebook — de-identified GDC role-choice data

Two files, both keyed on `team_id`. Neither contains any direct or indirect
identifier: no names, no school names, no class codes, no emails, no postcodes,
no free text. School and class keys are shuffled dummy IDs; first names are
replaced by a within-team `student_id`; school context is coarsened.

## `gdc_roles_deidentified.csv`

One row per **filled role slot** (i.e. one row per student in a role). Students
who fill more than one role appear in more than one row with the same
`student_id`.

| Variable | Type | Description |
|---|---|---|
| `team_id` | integer | Anonymous team key (stable within the dataset). |
| `year` | integer | Challenge cohort: 2023, 2024, or 2025. |
| `school_id` | string | **Dummy** school ID (`S001`…), shuffled so the ordering does not track the real school. Used as a random-effect grouping factor. |
| `class_id` | string | **Dummy** class ID, nested in school (`S001_C01`…). |
| `student_id` | integer | Within-team student index (`1…k`). Stable across the roles one student holds; **not** a person-level key and not comparable across teams. |
| `role` | string | Role taken: `team_captain`, `project_manager`, `art_lead`, `mechanics_lead`, `narrative_designer`, `head_scientist`, `communication_lead`, or `custom_role`. STEM roles = `head_scientist`, `mechanics_lead`. `custom_role` rows count toward team composition/size but are excluded from the role-choice models. |
| `gender` | string | Raw name-based gender label **before** the confidence threshold: `female`, `male`, or `unknown`. Provided so the threshold sensitivity analysis can be reproduced. |
| `gender_prob` | numeric | Confidence (0–1) reported by the name-to-gender lookup; `NA` if unmatched. |
| `gender_adj` | string | **Final** gender used in analysis: `female`/`male` if `gender_prob ≥ 0.90`, else `unknown`; unknowns at single-sex schools are backfilled to the school's gender. |
| `team_coed` | logical | `TRUE` if the team's school is co-educational with known composition; `FALSE` if single-sex; `NA` if unknown (all 2025). Used only by the team-formation null (Section 2), which excludes single-sex schools and 2025. |
| `school_single_sex` | string | School-level flag: `girls`, `boys`, or `coed` (`NA` if unknown). Drives the single-sex gender backfill and the "exclude single-sex schools" sensitivity check. |
| `school_icsea` | integer | ICSEA socioeconomic index of the school, **rounded to the nearest 10** to prevent triangulation. Public per-school figure; used (scaled) as a covariate. |
| `sector` | string | `Government`, `Non-government`, or `Homeschool`. |
| `locale` | string | Geographic locale, binned to `Metropolitan`, `Regional`, or `Remote`. |

## `gdc_topics_deidentified.csv`

One row per **team × open-ended science question**. Free-text answers are **not**
released; only the coded curriculum fields are.

| Variable | Type | Description |
|---|---|---|
| `team_id` | integer | Anonymous team key; join to the roles file for `team_gender`, `school_id`, etc. |
| `year` | integer | Cohort. |
| `question` | string | `learn_more` (science the team wished to learn more about — the analysed item) or `learnt_recently` (not analysed in the paper). |
| `Biological`,`Chemical`,`Physical`,`Earth_and_Space`,`DAT` | 0/1 | Multi-label indicators: did the team's answer name that Australian Curriculum field? A team may name several. `DAT` = Design & Technologies. |
| `n_fields` | integer | Number of fields named (0 if none/blank/off-topic). |
| `any_field` | 0/1 | 1 if the answer named at least one field. |
| `no_answer` | 0/1 | 1 if the answer was blank/non-committal/off-topic. |

A small number of teams (28) have two `learn_more` rows because their worksheet
was recorded across two exports. These are retained so the analysis reproduces
the published Table 2 exactly; de-duplicating them shifts the field prevalences
by well under a percentage point and does not change any contrast.

## Derived quantities (built in `analysis.qmd`)

`team_size`, `prop_boys`/`prop_girls` (among gender-known members), and
`team_gender` (`only boys` / `only girls` / `mixed` / `… + unknown`) are computed
from the roles file by counting distinct `student_id`s per team by `gender_adj`.
Analyses are restricted to teams of 3–6 members.

## De-identification notes

- **Removed entirely:** first name, school name, internal school key, class code,
  teacher email, team name, free-text answers, postcode, state, CALD indicator.
- **Coarsened:** ICSEA rounded to nearest 10; locale binned to three categories.
- **`sector`** is coded correctly here (`Government`/`Non-government`/`Homeschool`).
  The original follow-up script grouped sector via `str_detect("gov")`, which also
  matched "non-government"; the school-context-adjusted models (Section 6) may
  therefore differ marginally from the internal draft. The substantive
  conclusion — girls-only teams staff Head Scientist less often, and the effect
  persists after adjustment — is unchanged.
