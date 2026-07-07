# =============================================================================
# 00_deidentify.R
# Build the public, NON-IDENTIFIABLE replication dataset for the GDC role-choice
# paper from the internal analysis-ready master.
#
# WHAT THIS DOES
#   * removes every direct or indirect identifier (first names, school names,
#     school keys, class codes, teacher emails, team names, free-text answers,
#     postcodes, state);
#   * replaces school and class keys with shuffled dummy IDs (S001, S001_C01)
#     so nesting is preserved but no ordering leaks the real school;
#   * replaces first names with a within-team student index that still lets the
#     analysis dedupe students who hold >1 role (1,440 of ~3,900 students do);
#   * coarsens school context (ICSEA rounded to nearest 10; locale binned;
#     state and CALD dropped) to prevent triangulation back to a named school;
#   * keeps everything the analysis needs: role, inferred gender + probability,
#     final gender label, single-sex flags, sector, locale, ICSEA.
#
# WHAT IT WRITES
#   data/gdc_roles_deidentified.csv    <- commit this
#   data/gdc_topics_deidentified.csv   <- commit this
#   private/crosswalk_schools.csv      <- DO NOT COMMIT (gitignored)
#
# INPUTS (place the internal files here; this folder is gitignored)
#   raw/gdc_long_master.csv            (one row per team x role-slot x student)
#   raw/gdc_science_topics_by_team.csv (one row per team x question)
#
# This is the ONLY script that ever touches identifiable data. Everyone else
# runs analysis.qmd against the de-identified files, so this script does not
# need to be re-run to reproduce the paper.
# =============================================================================

suppressMessages(library(tidyverse))
set.seed(20260706)   # only used to shuffle the dummy-ID order

in_master <- "raw/gdc_long_master.csv"
in_topics <- "raw/gdc_science_topics_by_team.csv"
dir.create("data",    showWarnings = FALSE)
dir.create("private", showWarnings = FALSE)

master <- read_csv(in_master, show_col_types = FALSE)
topics <- read_csv(in_topics, show_col_types = FALSE)

# ---- dummy school IDs (shuffled so S001.. does not track school name order) --
schools <- master %>%
  distinct(school_id) %>%
  filter(!is.na(school_id)) %>%
  arrange(school_id) %>%
  slice_sample(prop = 1) %>%                       # shuffle
  mutate(school_dummy = sprintf("S%03d", row_number()))

# ---- dummy class IDs, nested within dummy school ----------------------------
classes <- master %>%
  distinct(school_id, class_code) %>%
  left_join(schools, by = "school_id") %>%
  arrange(school_dummy, class_code) %>%
  group_by(school_dummy) %>%
  mutate(class_dummy = sprintf("%s_C%02d", school_dummy, row_number())) %>%
  ungroup()

# ---- coarsening / recoding helpers ------------------------------------------
# single-sex flag from the SCHOOL %-girls field (used by the sensitivity battery
# and the single-sex backfill of gender): >90 -> girls' school, <10 -> boys'.
band_school_ss <- function(x) {
  v <- suppressWarnings(as.numeric(x))
  case_when(is.na(v) ~ NA_character_,
            v > 90   ~ "girls",
            v < 10   ~ "boys",
            TRUE     ~ "coed")
}
# co-ed flag from the TEAM %-girls field (used only by the team-formation null,
# which by design excludes single-sex schools and the 2025 cohort that has no
# team %-girls). Keeping this column NA for 2025 reproduces that exclusion.
band_team_coed <- function(x) {
  v <- suppressWarnings(as.numeric(x))
  ifelse(is.na(v), NA, v > 10 & v < 90)
}
# geographic locale binned to 3 broad categories (drops the finer ABS remoteness
# labels that could help triangulate a small school).
band_locale <- function(x) case_when(
  str_detect(x, "City")    ~ "Metropolitan",
  str_detect(x, "Regional")~ "Regional",
  str_detect(x, "Remote")  ~ "Remote",
  TRUE                     ~ NA_character_)
# sector, coded correctly as Government / Non-government / Homeschool.
# (NB: this corrects a str_detect("gov") quirk in the original follow-up script,
#  which matched "non-government" as well; see README.)
recode_sector <- function(x) {
  xl <- str_to_lower(x)
  case_when(is.na(x) | x == "" ~ NA_character_,
            xl == "government"      ~ "Government",
            xl == "non-government"  ~ "Non-government",
            TRUE                    ~ "Homeschool")
}

# ---- de-identified ROLE-SLOT table (one row per filled role slot) ------------
# Custom-role rows are KEPT (relabelled "custom_role"): they count toward team
# composition/size, exactly as in the internal pipeline. The role-choice models
# in analysis.qmd exclude them; only team composition uses them.
roles_deid <- master %>%
  filter(!is.na(name_raw)) %>%
  mutate(role = if_else(str_detect(role, "custom_role"), "custom_role", role)) %>%
  left_join(schools,  by = "school_id") %>%
  left_join(classes %>% select(school_id, class_code, class_dummy),
            by = c("school_id", "class_code")) %>%
  group_by(unique_team_id) %>%
  mutate(student_id = dense_rank(name_raw)) %>%   # stable per distinct name in team
  ungroup() %>%
  transmute(
    team_id           = unique_team_id,
    year              = as.integer(year),
    school_id         = school_dummy,
    class_id          = class_dummy,
    student_id,                                   # 1..k within team; not a person key
    role,
    gender            = gender,                    # raw genderize label (pre-threshold)
    gender_prob       = suppressWarnings(as.numeric(gender_prob)),
    gender_adj        = gender_adj,                # final: >=0.90 threshold + backfill
    team_coed         = band_team_coed(percent_girls),
    school_single_sex = band_school_ss(school_pct_girls),
    school_icsea      = round(suppressWarnings(as.numeric(school_icsea)) / 10) * 10,
    sector            = recode_sector(school_type),
    locale            = band_locale(school_location)
  ) %>%
  arrange(team_id, role, student_id)

# ---- de-identified SCIENCE-TOPIC table (coded fields only; no free text) -----
topics_deid <- topics %>%
  transmute(
    team_id         = unique_team_id,
    year            = as.integer(year),
    question,
    Biological, Chemical, Physical, Earth_and_Space, DAT,
    n_fields, any_field, no_answer
  ) %>%
  arrange(team_id, question)

# ---- write public files ------------------------------------------------------
write_csv(roles_deid,  "data/gdc_roles_deidentified.csv")
write_csv(topics_deid, "data/gdc_topics_deidentified.csv")

# ---- write the crosswalk PRIVATELY (never commit) ---------------------------
# lets you re-run from raw if needed; keep out of the repo.
write_csv(schools %>% select(school_dummy, school_id_internal = school_id),
          "private/crosswalk_schools.csv")

message("Wrote data/gdc_roles_deidentified.csv  (", nrow(roles_deid), " rows)")
message("Wrote data/gdc_topics_deidentified.csv (", nrow(topics_deid), " rows)")
message("Wrote private/crosswalk_schools.csv    (KEEP PRIVATE - do not commit)")

# ---- disclosure check: confirm no identifiers remain in the public files ----
stopifnot(!any(c("name_raw","student_name","school_name","teacher_email",
                 "team_name","class_code","raw_answer","school_pct_girls",
                 "percent_girls","school_state","postcode") %in% names(roles_deid)))
stopifnot(!any(c("school_name","teacher_email","team_name","class_code",
                 "raw_answer","classification") %in% names(topics_deid)))
message("Disclosure check passed: no identifying columns in public files.")
