# Trait QC PDF Review Guide

**Project:** BIODYNAMICS - Vegetation Co-occurrence
**Task:** Reviewing flagged trait values and suggesting corrections
**Version:** 2026-04-10

---

## Overview

Each PDF you receive covers one **trait domain** (e.g. *Leaf Area*, *Stem specific density*). Every page in the PDF shows **one taxon** that has been automatically flagged as having at least one suspected outlier value for that trait.

Your job is to look at each page, understand why the taxon was flagged, and write a suggested action in the **review table** provided separately.

> There are several hundred pages per PDF. Work through them in order. You do not need botanical expertise -- the plots are designed to make the answer visually obvious in most cases.

---

## What is on each page?

Each page has **four elements** arranged in three rows.

```
+----------------------------------+----------------------------------+
|  Distribution plot (left)        |  Family comparison plot (right)  |
+----------------------------------+----------------------------------+
|  Stats strip + heuristic label (bottom)                             |
+---------------------------------------------------------------------+
```

### Page title

At the very top you will see:

```
Taxon name  --  Trait domain
Heuristic: LABEL  |  Suggestion: ...
```

This is a quick summary. The label and suggestion are explained in detail below.

---

## Element 1 -- Distribution plot (top-left)

This plot shows **every raw measurement** recorded for this taxon x trait domain combination.

| What you see | What it means |
|---|---|
| **Dots (jittered)** | Individual records from the database. Each dot is one measurement from one source. |
| **Box** | Interquartile range (IQR = Q3 - Q1, i.e. the middle 50% of values). The middle line is the median. |
| **Dashed horizontal lines** | Inner Tukey fences: Q1 - 1.5xIQR (lower) and Q3 + 1.5xIQR (upper). Values beyond these are "mild outliers". |
| **Dotted horizontal lines** | Outer Tukey fences: Q1 - 3xIQR (lower) and Q3 + 3xIQR (upper). Values beyond these are "extreme outliers". |
| **Dot colour -- grey/blue** | Value is within the inner fence (not flagged). |
| **Dot colour -- orange** | Mild outlier (beyond inner fence but within outer fence). |
| **Dot colour -- red** | Extreme outlier (beyond outer fence). |

**If multiple trait names exist under the same domain** (e.g. leaf area measured in mm2 and cm2), the plot is split into side-by-side panels -- one panel per measurement unit. This is important: a value that looks like an outlier may simply be in different units.

**What to look for:**

- Are the outlier dots far from the rest, or just slightly beyond the fence?
- Are all outliers on the same side (all high / all low), or scattered?
- Is the box very narrow (tight cluster) with one or a few extreme points?
- Does the scale look wrong? For example, a leaf area of 100,000 mm2 when all others are around 50 mm2 suggests a unit error (cm2 recorded as mm2).

---

## Element 2 -- Family comparison plot (top-right)

This plot places the **focal taxon's median** in the context of all other taxa in the same **taxonomic family** that have enough records (minimum 5 records by default).

| What you see | What it means |
|---|---|
| **Grey dots (jittered)** | Median trait value of each qualifying family member. |
| **Red/firebrick dot** | Median trait value of the focal taxon. |
| **x-axis (log10 scale)** | Trait value. The log scale is used because trait values span many orders of magnitude. |

**What to look for:**

- Is the red dot far from the cluster of grey dots?
  - If yes: the taxon's median is unusual for its family -- likely a real problem.
  - If no: the taxon fits in with its relatives -- the flagged values may be genuine biological variation.
- If the plot shows "No family data" or only the red dot: there are no relatives in the database with enough records to compare against. You cannot use this panel for that taxon -- rely on the distribution plot alone.

---

## Element 3 -- Stats strip (bottom panel)

A plain text bar showing the key numbers for this taxon x domain group:

| Field | Meaning |
|---|---|
| `n` | Total number of records |
| `outliers = X (Y%)` | Number and proportion of suspected outlier records |
| `direction` | Whether outliers are **ALL HIGH**, **ALL LOW**, or **MIXED** |
| `CV` | Coefficient of variation in % (standard deviation / mean x 100). A very high CV means values are widely spread. |
| `mean/median` | Ratio of mean to median. A ratio far from 1 indicates skew, often caused by a few extreme values pulling the mean. |
| `priority` | Automated priority score (higher = should be reviewed first). Formula: outlier_fraction x log10(n + 1). |
| `corrected` | **YES [already corrected]** means a correction has already been entered in the manual corrections file. **no** means nothing has been done yet. |

---

## Element 4 -- Heuristic label and suggestion

The coloured background and bold label in the stats strip is the **automated heuristic recommendation**. It is a starting point, not a final answer -- you need to look at the plots to confirm or override it.

| Label | Colour | Meaning | Typical action |
|---|---|---|---|
| **PROBABLY OK** | Green | Single outlier in a large sample (n >= 10, outlier fraction < 10%). | Usually no action needed. Confirm visually and mark as "Accept". |
| **SMALL SAMPLE** | Grey | Five or fewer records -- too few to assess statistically. | Check the distribution plot. If one value is wildly different from the rest, flag for removal. Otherwise mark "Accept". |
| **ZERO-IQR** | Blue | All values are identical (IQR = 0). The "outlier" is anything deviating from this constant. | Check whether the records are truly all the same value or whether this is a data entry artefact. |
| **SCALE ISSUE** | Red | Mean/median ratio >= 5 and outliers all on one side. Strongly suggests a unit conversion error. The suggestion field shows the likely scale factor (e.g. `scale_factor = 0.01` means divide by 100). | Check the unit in the distribution plot's panel labels. If a unit conversion explains everything, record the scale factor in the correction table. |
| **HIGH FRACTION** | Red | More than 50% of records are flagged as outliers. | Look carefully. Either the species genuinely has highly variable trait values, or the bulk of records are correct and a small cluster is wrong. Mark accordingly. |
| **REVIEW** | Orange | None of the above categories apply -- manual inspection needed. | This is the most common label. Read the plots carefully and decide. |

---

## Step-by-step review workflow

### Step 1 -- Read the page title

Note the taxon name, trait domain, and the heuristic label.

### Step 2 -- Look at the distribution plot

- Identify which dots are coloured orange or red (outliers).
- Estimate how far they are from the bulk of the data.
- Check if the scale could explain the outliers (e.g. values in different units).
- Note the direction: are all outliers high, all low, or mixed?

### Step 3 -- Look at the family comparison plot

- Check whether the focal taxon's median (red dot) is inside or far outside the family cloud (grey dots).
- If the family comparison agrees with the distribution plot (both suggest the value is wrong), your confidence should be high.
- If they disagree, be more cautious.

### Step 4 -- Read the stats strip

- A `mean/median` ratio far from 1 (e.g. > 3) together with `direction = ALL HIGH` and a **SCALE ISSUE** label is a strong signal for a unit error.
- High `CV` alone does not mean the data are wrong -- some traits are genuinely variable.
- If `corrected = YES [already corrected]`, check whether the correction looks sufficient based on the plots. If not, flag it for further review.

### Step 5 -- Record your decision

In the review spreadsheet, for each taxon x domain record one of the following in the **Action** column:

| Action | When to use |
|---|---|
| `Accept` | The flagged values look like genuine biological variation. No change needed. |
| `Remove outlier(s)` | One or a few specific extreme values should be dropped. Note the approximate value(s) in the Comments column. |
| `Scale correction` | All values need to be multiplied by a constant (unit error). Write the correction factor, e.g. `x 0.01`. |
| `Remove all` | The entire taxon x domain group looks unreliable (e.g. clearly wrong units throughout, or the data source is suspect). |
| `Uncertain` | You cannot decide from the plots alone. Flag for discussion. |

Always add a brief note in the **Comments** column explaining your reasoning, especially for `Remove` and `Scale correction` decisions.

---

## Common patterns and how to recognise them

### Unit error (most common problem)

**Signs:**

- Heuristic says **SCALE ISSUE**
- Distribution plot: one cluster of values is 10x, 100x, or 1000x larger/smaller than the rest
- Family comparison: red dot is far above or below the grey cloud
- Stats strip: `mean/median` ratio is large (> 5), `direction = ALL HIGH` or `ALL LOW`
- Panel labels in the distribution plot often reveal the unit: e.g. one panel says "mm2" and another says "cm2"

**Action:** `Scale correction` -- write the factor (e.g. `x 0.01` to convert cm2 to mm2).

---

### Single extreme measurement (common)

**Signs:**

- Heuristic says **PROBABLY OK** or **REVIEW**
- Distribution plot: one red dot far above or below a tight cluster
- Family comparison: focal taxon median is close to the family cloud (because the outlier barely affects the median)
- Stats strip: `n` is large, `outlier fraction` is small

**Action:** `Accept` (if n >= 10 and fraction < 5%) or `Remove outlier(s)` (if the value is biologically implausible -- e.g. leaf area of 0.0001 mm2).

---

### All values identical (ZERO-IQR)

**Signs:**

- Heuristic says **ZERO-IQR**
- Distribution plot: all dots at the same y-position; the "outlier" is just one slightly different value

**Action:** Usually `Accept` unless the constant value itself looks wrong.

---

### Genuinely variable taxon

**Signs:**

- Heuristic says **REVIEW** or **HIGH FRACTION**
- Distribution plot: values spread over a wide range with no obvious gap
- Family comparison: grey dots also span a wide range (the family is naturally variable)
- Stats strip: high `CV`, `direction = MIXED`

**Action:** `Accept`. High natural variation is real -- do not remove values just because the CV is high.

---

### Too few records to assess

**Signs:**

- Heuristic says **SMALL SAMPLE** (n <= 5)
- Distribution plot: only a few dots, hard to tell what is "normal"

**Action:** `Accept` unless one value is biologically impossible (e.g. negative leaf area or a value several orders of magnitude from the others).

---

## Frequently asked questions

**Q: Should I look up the species in a reference?**
A: Only if you are genuinely uncertain and the case is important. For routine reviews, the family comparison panel is usually sufficient context.

**Q: What counts as a "biologically impossible" value?**
A: Examples: negative trait values (all traits here are positive by definition); leaf area > 1 m2 for a herbaceous plant; stem density > 5 g/cm3 (wood is denser than water at ~1 g/cm3, most wood is 0.2-1.2 g/cm3). When in doubt, mark `Uncertain`.

**Q: The family comparison shows no grey dots. What do I do?**
A: The taxon's family has no other members with enough records. Rely on the distribution plot alone.

**Q: The page says `corrected = YES [already corrected]`. Should I still review it?**
A: Yes. The correction was applied automatically based on earlier rules. Your job is to check that the correction looks adequate based on the plots.

**Q: There are multiple facets in the distribution plot. Why?**
A: The trait domain contains records collected with different measurement units or methods (e.g. leaf area in mm2 from one database and in cm2 from another). Each facet is one measurement variant. Outliers in one facet but not another are a strong sign of a unit mismatch.

---

## Quick reference card

```
TOP-LEFT plot    Distribution of individual records
                 > grey/blue dot = within fence (OK)
                 > orange dot    = mild outlier (1.5x IQR)
                 > red dot       = extreme outlier (3x IQR)
                 > dashed line   = inner fence (1.5x IQR)
                 > dotted line   = outer fence (3x IQR)

TOP-RIGHT plot   Family context (log10 scale)
                 > grey dots     = family members (median)
                 > red dot       = focal taxon (median)

BOTTOM strip     Key numbers + heuristic label
                 > GREEN  = PROBABLY OK   -> likely accept
                 > GREY   = SMALL SAMPLE  -> check individually
                 > BLUE   = ZERO-IQR      -> check artefact
                 > RED    = SCALE ISSUE   -> unit error likely
                 > RED    = HIGH FRACTION -> many outliers
                 > ORANGE = REVIEW        -> manual decision
```
