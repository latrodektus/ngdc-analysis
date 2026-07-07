# Gendered role choice in a primary-school STEAM challenge — replication package

Data and code to reproduce every figure and table in:

> **The gendering of scientific roles in childhood is produced by mixed-gender
> groups, not carried into them.** Pollo, Kasumovic et al.

Primary-school children (school years 3–6) in Australia's National Game Design
Challenge (2023–2025) formed their own teams, recorded the science they were
interested in, and assigned each member a role. The analysis asks whether the
gendering of scientific role choice is a disposition children carry into every
group or something the mixed-gender group produces, using naturally occurring
single-gender and mixed teams as the contrast.

## What's here

```
analysis.qmd                     # reproduces all figures + tables from the public data
R/00_deidentify.R                # how the public data was built from the raw master (raw not shared)
data/
  gdc_roles_deidentified.csv     # student × role rows (dummy IDs, no names)
  gdc_topics_deidentified.csv    # coded science-topic responses (no free text)
  codebook.md                    # full variable documentation
output/figures, output/tables    # written by analysis.qmd
LICENSE                          # MIT (code) + CC-BY-4.0 (data)
CITATION.cff
```

## Reproduce the analysis

Requires R (≥ 4.4) and Quarto. Install packages:

```r
install.packages(c("tidyverse", "glmmTMB", "emmeans", "survival",
                   "broom", "logistf"))   # logistf is optional
```

Then render:

```bash
quarto render analysis.qmd
```

or run interactively in Positron/RStudio. All randomisation uses
`set.seed(1234)` and 1,000 permutations, so results are exactly reproducible.
Figures are written to `output/figures/` and every table to `output/tables/`.

## Data privacy

The released data contain **no identifiable information**. The only personal
detail ever recorded by the program was a first name, which is used solely to
infer likely gender and is **not** included here. School and class identifiers
are shuffled dummy codes; school context (ICSEA, sector, locale) is coarsened so
it cannot be triangulated back to a named school. See `data/codebook.md` for the
full de-identification record.

The script `R/00_deidentify.R` documents exactly how the public files were
produced from the internal master. That master, and the dummy-ID crosswalk, are
**not** distributed and are excluded by `.gitignore`; the analysis does not need
them.

## Ethics and consent

Data were collected by Arludo Pty Ltd during the National Game Design Challenge
and analysed under UNSW Sydney Human Research Ethics approval (XXXXXX) with a
waiver of consent for secondary use of records held under a data-minimisation
policy (first name only). Results are reported only in aggregate.

## Conflict of interest

Author M. Kasumovic is Director of Arludo Pty Ltd, which ran the challenge and
provided the data. This interest is declared and managed by UNSW under an
existing arrangement overseen by his Head of School.

## Citation

See `CITATION.cff`. Please cite the paper and this repository if you reuse the
data or code.

## License

Code is released under the MIT License; the data files in `data/` are released
under [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). See `LICENSE`.
