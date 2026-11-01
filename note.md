# HR Attrition Analytics -- Technical Notes & Methodology

> **Project:** End-to-End HR Attrition Analytics (SQL + Power BI)\
> **Dataset:** IBM HR Analytics Employee Attrition
> (`WA_Fn-UseC_-HR-Employee-Attrition.csv`)\
> **Database:** SQLite (DB Browser for SQLite)\
> **BI tool:** Power BI Desktop\
> **Main table:** `employees`

------------------------------------------------------------------------

## 1. Project purpose

The purpose of this project is to understand which employee groups have
higher attrition rates and to turn the analysis into an interactive HR
dashboard.

The work is divided into three layers:

1.  **SQL analysis:** data validation, KPI calculations, segmentation,
    tenure and income banding, conditional-aggregation pivots,
    risk-profile analysis, and numeric comparisons.
2.  **Power BI:** explicit DAX measures, calculated tenure band, income
    quartile preparation, interactive slicers, KPI cards, charts, and a
    matrix.
3.  **Communication:** an executive summary that explains the evidence,
    recommends actions, and states the limitations.

The analysis is descriptive. It identifies patterns and associations; it
does not prove that a particular factor causes an employee to leave.

## 2. Dataset and data preparation

### 2.1 Dataset overview

The source is the IBM HR Analytics Employee Attrition sample dataset.

  Item                                            Value
  -------------------------------------------- --------
  Original employee records                       1,470
  Original source columns                            35
  Employees who stayed (`Attrition = No`)         1,233
  Employees who left (`Attrition = Yes`)            237
  Overall attrition rate                         16.12%
  Missing values found in checked key fields          0

The CSV was imported into DB Browser for SQLite as a table named
`employees`.

### 2.2 Table structure and attrition flag

The original `Attrition` column contains text values (`Yes` and `No`). A
numeric binary field named `attrition_flag` was added so that attrition
can be counted consistently in SQL and Power BI:

-   `Yes` becomes `1` (employee left).
-   `No` becomes `0` (employee stayed).

One-time SQLite setup commands:

``` sql
ALTER TABLE employees ADD COLUMN attrition_flag INTEGER;

UPDATE employees
SET attrition_flag = CASE
    WHEN Attrition = 'Yes' THEN 1
    WHEN Attrition = 'No' THEN 0
    ELSE NULL
END;
```

**Why this was done:** a numeric flag makes it easier to calculate
attrition counts and build DAX measures. The original text column was
retained for readability and validation.

> These are one-time setup statements. Do not run `ALTER TABLE` again if
> `attrition_flag` already exists.

### 2.3 Validation checks

The following checks were used:

``` sql
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT EmployeeNumber) AS unique_employees
FROM employees;
```

``` sql
SELECT
    SUM(CASE WHEN EmployeeNumber IS NULL THEN 1 ELSE 0 END) AS null_employee_id,
    SUM(CASE WHEN Attrition IS NULL THEN 1 ELSE 0 END) AS null_attrition,
    SUM(CASE WHEN Department IS NULL THEN 1 ELSE 0 END) AS null_department,
    SUM(CASE WHEN MonthlyIncome IS NULL THEN 1 ELSE 0 END) AS null_income,
    SUM(CASE WHEN JobRole IS NULL THEN 1 ELSE 0 END) AS null_job_role
FROM employees;
```

``` sql
SELECT
    Attrition,
    COUNT(*) AS employee_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM employees), 2) AS percentage
FROM employees
GROUP BY Attrition
ORDER BY Attrition;
```

**Validation result:** 1,470 rows and 1,470 distinct employee numbers
were found. The checked key columns had no NULL values. The class
balance was 1,233 retained employees (83.88%) and 237 employees who left
(16.12%).

------------------------------------------------------------------------

## 3. SQL analysis -- all 12 questions

The complete executable SQL script is supplied separately as
`queries.sql`. It contains the table definition documentation, setup
statements, and all 12 commented analytical queries.

### Q1 -- Load and flag

**What it does:** documents the `employees` table structure and creates
`attrition_flag`.

**Why:** establishes a consistent employee-level table and a numeric
outcome field for analysis.

The DDL is included in `queries.sql`. The CSV was imported using DB
Browser for SQLite's CSV import workflow. The DDL is documented in the
script; it should not be run on top of an already-imported table.

### Q2 -- Data validation

**What it does:** checks row count, distinct employee identifiers, NULLs
in key fields, and the attrition class balance.

**Why:** validates that the imported data is complete enough for the
planned analysis and that the outcome distribution is understood before
calculating rates.

**Result:** 1,470 records, 1,470 distinct `EmployeeNumber` values, zero
NULLs in the checked key columns, and 237 attrition cases.

### Q3 -- KPI summary by attrition status

**What it does:** groups employees by `Attrition` and calculates
employee count, share of the full dataset, overall attrition rate,
average monthly income, average company tenure, and average job
satisfaction.

**Why:** compares employees who left with employees who stayed, rather
than looking only at the overall average.

  Metric                                             Stayed (`No`)   Left (`Yes`)
  ------------------------------------------------ --------------- --------------
  Employees                                                  1,233            237
  Share of dataset                                          83.88%         16.12%
  Overall attrition rate shown in grouped output            16.12%         16.12%
  Average monthly income                                  6,832.74       4,787.09
  Average years at company                                    7.37           5.13
  Average job satisfaction                                    2.78           2.47

**Interpretation:** in this dataset, employees who left had lower
average monthly income, shorter average tenure, and slightly lower
average job satisfaction than employees who stayed.

### Q4 -- Attrition by department

**What it does:** groups by `Department`, calculates headcount and
attrition count, and divides attritions by headcount.

**Why:** identifies which organizational departments have higher
observed attrition rates.

  Department                 Headcount   Attritions   Attrition rate
  ------------------------ ----------- ------------ ----------------
  Sales                            446           92           20.63%
  Human Resources                   63           12           19.05%
  Research & Development           961          133           13.84%

### Q5 -- Attrition by job role

**What it does:** groups by `JobRole`, calculates headcount, attritions,
and attrition rate, and applies `HAVING COUNT(*) >= 30`.

**Why:** avoids ranking very small groups where a small number of
departures can create an unstable percentage.

  Job role                      Headcount   Attritions   Attrition rate
  --------------------------- ----------- ------------ ----------------
  Sales Representative                 83           33           39.76%
  Laboratory Technician               259           62           23.94%
  Human Resources                      52           12           23.08%
  Sales Executive                     326           57           17.48%
  Research Scientist                  292           47           16.10%
  Manufacturing Director              145           10            6.90%
  Healthcare Representative           131            9            6.87%
  Manager                             102            5            4.90%
  Research Director                    80            2            2.50%

### Q6 -- Employee characteristics

**What it does:** uses `UNION ALL` to return attrition rates by
overtime, marital status, business travel, and gender in one result set.

**Why:** compares multiple employee characteristics using the same rate
definition: attrition count divided by segment headcount.

**OverTime**

  Segment     Headcount   Attritions   Attrition rate
  --------- ----------- ------------ ----------------
  Yes               416          127           30.53%
  No              1,054          110           10.44%

**Marital status**

  Segment      Headcount   Attritions   Attrition rate
  ---------- ----------- ------------ ----------------
  Single             470          120           25.53%
  Married            673           84           12.48%
  Divorced           327           33           10.09%

**Business travel**

  Segment               Headcount   Attritions   Attrition rate
  ------------------- ----------- ------------ ----------------
  Travel_Frequently           277           69           24.91%
  Travel_Rarely             1,043          156           14.96%
  Non-Travel                  150           12            8.00%

**Gender**

  Segment     Headcount   Attritions   Attrition rate
  --------- ----------- ------------ ----------------
  Male              882          150           17.01%
  Female            588           87           14.80%

### Q7 -- Tenure bands

**What it does:** uses `CASE WHEN` to assign each employee to one of
four company-tenure bands:

-   `0-2 years`
-   `3-5 years`
-   `6-10 years`
-   `11+ years`

Then it calculates headcount, attritions, and attrition rate for each
band.

**Why:** tenure bands make the relationship between length of service
and attrition easier to interpret and communicate than dozens of
individual year values.

  Tenure band     Headcount   Attritions   Attrition rate
  ------------- ----------- ------------ ----------------
  0--2 years            342          102           29.82%
  3--5 years            434           60           13.82%
  6--10 years           448           55           12.28%
  11+ years             246           20            8.13%

The SQL query uses an explicit `CASE` expression in `ORDER BY` to
preserve the natural band order rather than alphabetically sorting the
labels.

### Q8 -- Income quartiles

**What it does:** uses the SQL window function
`NTILE(4) OVER (ORDER BY MonthlyIncome)` to divide employees into four
approximately equal-sized income groups, then calculates attrition by
quartile.

**Why:** quartiles make it possible to compare the lowest-income group
with progressively higher-income groups without choosing arbitrary
salary cutoffs.

  Income quartile          Headcount   Attritions   Attrition rate
  ---------------------- ----------- ------------ ----------------
  Q1 -- lowest income            368          108           29.35%
  Q2                             368           52           14.13%
  Q3                             367           39           10.63%
  Q4 -- highest income           367           38           10.35%

`NTILE(4)` creates groups of nearly equal size. When values tie, rows
with the same income can fall on different sides of a quartile boundary
because the window ordering is based on `MonthlyIncome`.

### Q9 -- Department × Job Satisfaction pivot

**What it does:** uses conditional aggregation
(`SUM(CASE WHEN ... THEN ... END)`) to calculate the attrition rate
separately for satisfaction levels 1, 2, 3, and 4 within each
department.

**Why:** a pivot layout makes it easier to compare satisfaction groups
across departments in one result.

  -------------------------------------------------------------------------
  Department    Satisfaction 1 Satisfaction 2 Satisfaction 3 Satisfaction 4
  ------------- -------------- -------------- -------------- --------------
  Human                 45.45%         10.00%         20.00%         11.76%
  Resources                                                  

  Research &            19.79%         13.79%         14.33%          9.49%
  Development                                                

  Sales                 26.74%         23.26%         21.26%         14.97%
  -------------------------------------------------------------------------

`NULLIF(denominator, 0)` protects the calculation from division by zero
if a department has no employees in a particular rating group.

### Q10 -- Department × Work-Life Balance pivot

**What it does:** uses the same conditional-aggregation approach for
WorkLifeBalance levels 1--4.

**Why:** compares attrition across work-life balance ratings within each
department.

  Department                 Balance 1   Balance 2   Balance 3   Balance 4
  ------------------------ ----------- ----------- ----------- -----------
  Human Resources                0.00%      28.57%      21.43%      10.00%
  Research & Development        31.67%      13.62%      11.83%      15.38%
  Sales                         37.50%      23.53%      18.12%      23.08%

As in Q9, `NULLIF` prevents division-by-zero errors.

### Q11 -- Multi-factor risk profiles

**What it does:** combines three factors for each employee: -
`OverTime` - tenure band - income quartile using `NTILE(4)`

It groups employees by those factors, calculates headcount, attritions,
and attrition rate, excludes groups with fewer than 20 employees using
`HAVING COUNT(*) >= 20`, and returns the three highest rates.

**Why:** one-variable analysis can hide combinations of risk factors.
The minimum headcount threshold reduces the chance of highlighting a
tiny group with an extreme but unstable rate.

  Risk profile                        Headcount   Attritions   Attrition rate
  --------------------------------- ----------- ------------ ----------------
  Overtime Yes + 0--2 years + Q1             45           32           71.11%
  Overtime Yes + 3--5 years + Q1             37           19           51.35%
  Overtime Yes + 6--10 years + Q1            22           11           50.00%

These are observed high-rate segments in this dataset, not proof that
the combination causes attrition.

### Q12 -- Numeric means by attrition flag

**What it does:** groups by `attrition_flag` and calculates the mean of
the numeric source columns.

**Why:** provides a broad descriptive comparison of numeric employee
characteristics between employees who stayed and employees who left. It
can help identify variables worth investigating further.

Selected results:

  Numeric variable             Stayed (`0`)   Left (`1`)
  -------------------------- -------------- ------------
  Age                                 37.56        33.61
  DailyRate                          812.50       750.36
  DistanceFromHome                     8.92        10.63
  EnvironmentSatisfaction              2.77         2.46
  JobInvolvement                       2.77         2.52
  JobLevel                             2.15         1.64
  JobSatisfaction                      2.78         2.47
  MonthlyIncome                    6,832.74     4,787.09
  NumCompaniesWorked                   2.65         2.94
  RelationshipSatisfaction             2.73         2.60
  StockOptionLevel                     0.85         0.53
  TotalWorkingYears                   11.86         8.24
  TrainingTimesLastYear                2.83         2.62
  WorkLifeBalance                      2.78         2.66
  YearsAtCompany                       7.37         5.13
  YearsInCurrentRole                   4.48         2.90
  YearsSinceLastPromotion              2.23         1.95
  YearsWithCurrManager                 4.37         2.85

The query also includes `EmployeeCount`, `EmployeeNumber`, and
`StandardHours` for numeric-column completeness. These are
technical/identifier fields and should not be interpreted as meaningful
attrition drivers.

------------------------------------------------------------------------

## 4. Power BI data model and transformations

### 4.1 Import

The `employees` table was exported from SQLite to CSV and imported into
Power BI using **Get Data → Text/CSV**. Power Query was used to inspect
the imported columns and apply the appropriate data types before
selecting **Close & Apply**.

The model contains one main employee table named `employees`. Since the
report uses a single employee-level table, no relationship between
multiple tables was required.

### 4.2 Tenure band calculated column

A calculated column was created in Power BI so the same tenure groups
could be used in report visuals and slicers.

``` dax
tenure_band =
SWITCH(
    TRUE(),
    employees[years_at_company] <= 2, "0-2 years",
    employees[years_at_company] <= 5, "3-5 years",
    employees[years_at_company] <= 10, "6-10 years",
    "11+ years"
)
```

**Why `SWITCH(TRUE())` was used:** it evaluates the conditions from top
to bottom and returns the label for the first matching range. This is a
readable way to implement multiple ordered ranges in a calculated
column.

A helper sort column was also created:

``` dax
tenure_band_sort =
SWITCH(
    employees[tenure_band],
    "0-2 years", 1,
    "3-5 years", 2,
    "6-10 years", 3,
    "11+ years", 4
)
```

Then `tenure_band` was selected and sorted by `tenure_band_sort` using
**Column tools → Sort by column**. This prevents text sorting from
putting the bands in alphabetical order.

### 4.3 Income quartile in Power Query

The income quartile was first explored as a DAX calculated column.
However, tied monthly-income values and sorting dependencies made that
approach less reliable for matching the SQL `NTILE(4)` grouping.

The final Power Query method was:

1.  Open **Home → Transform data**.
2.  Select the `employees` query.
3.  Sort `monthly_income` in ascending order.
4.  Choose **Add Column → Index Column → From 1**.
5.  Add a Custom Column with this expression:

``` powerquery
if [Index] <= 368 then "Q1"
else if [Index] <= 736 then "Q2"
else if [Index] <= 1103 then "Q3"
else "Q4"
```

6.  Name the resulting column `income_quartile` (it was temporarily
    named `income_quartile_new` during replacement of the earlier DAX
    version).
7.  Apply the changes using **Close & Apply**.

**Why this was done:** the sorted index assigns the first 368 employees
to Q1, the next 368 to Q2, the next 367 to Q3, and the final 367 to Q4.
This reproduces the intended group sizes from the SQL quartile output.

The quartile order in the report is Q1, Q2, Q3, Q4. A separate sort
column was ultimately not required for the final chart because the
visual's ascending sort produced the desired order.

> Important: the Power Query method relies on the same ascending income
> ordering as the SQL quartile calculation. If the source data or row
> ordering changes, refresh and re-check the quartile boundaries and
> cross-validation results.

------------------------------------------------------------------------

## 5. DAX measures -- definitions and reasons

The following explicit measures were created in the `employees` table.
The actual imported field names used in the final model include
snake_case names such as `monthly_income` and `years_at_company`.

### 5.1 Headcount

``` dax
Headcount =
COUNTROWS(employees)
```

**Purpose:** counts the employee records in the current filter context.

**Why:** when a user selects a department, job role, overtime group,
tenure band, or income quartile, the measure returns the number of
employees in that selected segment.

### 5.2 Attritions

``` dax
Attritions =
CALCULATE(
    COUNTROWS(employees),
    employees[attrition_flag] = 1
)
```

**Purpose:** counts employees whose binary attrition flag equals 1.

**Why `CALCULATE` was used:** `CALCULATE` modifies the filter context to
include only employees with `attrition_flag = 1`, while retaining the
other report filters. For example, selecting Sales and Overtime = Yes
returns attritions within that segment.

### 5.3 Attrition Rate %

``` dax
Attrition Rate % =
DIVIDE(
    [Attritions],
    [Headcount],
    0
)
```

**Purpose:** calculates the share of employees in the current context
who left.

**Why `DIVIDE` was used:** it safely handles a zero denominator. The
third argument returns 0 if the denominator is zero, rather than raising
a division error.

**Formatting:** the measure was formatted as Percentage with two decimal
places.

### 5.4 Avg Monthly Income

``` dax
Avg Monthly Income =
AVERAGE(employees[monthly_income])
```

**Purpose:** calculates the average monthly income for the current
selection.

**Why:** allows the report to compare compensation levels across
departments and employee segments. It also changes dynamically when
slicers are used.

### 5.5 Avg Years At Company

``` dax
Avg Years At Company =
AVERAGE(employees[years_at_company])
```

**Purpose:** calculates average company tenure in the current filter
context.

**Why:** provides an overall tenure KPI and can be used to compare
selected employee groups.

### 5.6 Expected unfiltered measure values

With no slicers selected, the main measures should return:

  Measure                          Expected value
  ---------------------- ------------------------
  Headcount                                 1,470
  Attritions                                  237
  Attrition Rate %                         16.12%
  Avg Monthly Income       approximately 6,501.50
  Avg Years At Company         approximately 7.01

The Card visual's **Display units** setting was changed to **None** for
Headcount so it displays `1,470` rather than a rounded `1K`.

------------------------------------------------------------------------

## 6. Power BI report design

### 6.1 Page 1 -- Executive Overview

The first page is intended as the management-facing summary page. It
includes KPI cards and visuals for the main attrition patterns.

Implemented elements:

-   KPI cards for Headcount, Attritions, Attrition Rate %, Avg Monthly
    Income, and Avg Years At Company.
-   Horizontal bar chart: **Attrition Rate % by Department**.
-   Horizontal bar chart: **Attrition Rate % by Job Role**.
-   Column chart: **Attrition Rate by Tenure Band**.
-   Matrix: **Department by Overtime**, showing attrition rate for
    Overtime = No and Yes.

Key values shown by the visuals:

-   Department: Sales 20.63%, Human Resources 19.05%, Research &
    Development 13.84%.
-   Job roles: Sales Representative 39.76%, Laboratory Technician
    23.94%, Human Resources 23.08% (other roles are also included where
    the report visual displays them).
-   Tenure: 0--2 years 29.82%, 3--5 years 13.82%, 6--10 years 12.28%,
    11+ years 8.13%.
-   Overtime matrix: overall Yes 30.53% versus No 10.44%.

**Final implementation:** the delivered Executive Overview matrix uses
Department as rows and Overtime as columns, with Attrition Rate % as the
value. The separate SQL Department × JobSatisfaction pivot is available
in Q9. If an assessment rubric explicitly requires the Job Satisfaction
matrix on the report page, add it as an additional matrix; it is not the
matrix currently shown in the saved screenshot.

### 6.2 Page 2 -- Segment Explorer

The second page is intended for interactive exploration by HR users.

Implemented slicers:

-   `department`
-   `job_role`
-   `over_time`
-   `tenure_band`
-   `income_quartile`

Implemented visuals:

-   KPI cards: Total Employees (Headcount), Total Attritions, Attrition
    Rate %.
-   Column chart: Attrition Rate % by Overtime.
-   Column chart: Attrition Rate % by Income Quartile.

The cards and charts respond to the active slicers. This allows a user
to select a segment and see its headcount, attrition count, and rate.

**Final implementation note:** the delivered Segment Explorer contains
the slicers, KPI cards, overtime and income-quartile charts,
decomposition tree, and What-if scenario panel. A separate ranked
segment table with headcount was not included in the final page. Add it
only if the project rubric explicitly requires that extra table.

------------------------------------------------------------------------

## 7. SQL-to-DAX cross-validation

Cross-validation checks whether the Power BI measures reproduce the SQL
segment calculations. The same segment filters were applied in Power BI,
and the resulting Headcount, Attritions, and Attrition Rate were
compared with the SQL outputs.

  Segment               Metric                SQL   Power BI Result
  --------------------- ---------------- -------- ---------- --------
  Overtime = Yes        Headcount             416        416 Match
  Overtime = Yes        Attritions            127        127 Match
  Overtime = Yes        Attrition rate     30.53%     30.53% Match
  Overtime = No         Headcount           1,054      1,054 Match
  Overtime = No         Attritions            110        110 Match
  Overtime = No         Attrition rate     10.44%     10.44% Match
  Department = Sales    Headcount             446        446 Match
  Department = Sales    Attritions             92         92 Match
  Department = Sales    Attrition rate     20.63%     20.63% Match
  Tenure = 0--2 years   Headcount             342        342 Match
  Tenure = 0--2 years   Attritions            102        102 Match
  Tenure = 0--2 years   Attrition rate     29.82%     29.82% Match

**Conclusion:** the three required segment checks (Overtime, Sales
department, and 0--2 years tenure) matched exactly between SQL and Power
BI. Overtime was checked for both Yes and No groups.

### Why cross-validation matters

A measure can show a plausible percentage but still be wrong if it
ignores slicer filters or uses the wrong denominator. Comparing the same
segment in SQL and Power BI verifies that:

-   the numerator is the number of attrition cases in the selected
    segment;
-   the denominator is the headcount in that same segment;
-   the DAX measure responds to filter context as intended;
-   the Power Query tenure and income groupings are aligned with the SQL
    analysis.

------------------------------------------------------------------------

## 8. Main analytical conclusions

The strongest observed patterns in this dataset are:

1.  Employees working overtime have a higher attrition rate (30.53%)
    than employees not working overtime (10.44%).
2.  Employees with 0--2 years of tenure have the highest tenure-band
    attrition rate (29.82%).
3.  The lowest income quartile has the highest income-quartile attrition
    rate (29.35%).
4.  Sales has the highest departmental attrition rate (20.63%).
5.  Sales Representatives have the highest job-role attrition rate among
    roles with at least 30 employees (39.76%).
6.  The highest multi-factor profile is Overtime = Yes, tenure = 0--2
    years, income = Q1, with 71.11% attrition among 45 employees.

These results support targeted retention monitoring, but they should be
treated as descriptive associations rather than causal findings.

------------------------------------------------------------------------

## 9. Limitations and interpretation cautions

-   **Synthetic/sample data:** this is the IBM HR Analytics sample
    dataset, not a verified live employee database from the organization
    making decisions.
-   **No time dimension:** there is no detailed date of hire/exit or
    event timeline suitable for a time-series attrition trend analysis.
-   **Correlation is not causation:** overtime, lower income, shorter
    tenure, and job role are associated with different attrition rates,
    but the analysis does not prove they cause employees to leave.
-   **No predictive model:** the work is descriptive segmentation and
    dashboarding, not a validated employee-level prediction system.
-   **Unobserved factors:** management quality, employee feedback,
    organizational culture, external job opportunities, and personal
    circumstances are not fully represented.
-   **Small groups:** rates from small groups can be unstable. The
    job-role query uses a minimum headcount of 30, and the multi-factor
    profile query uses a minimum headcount of 20.
-   **Quartile boundary ties:** SQL `NTILE(4)` and Power Query's
    sorted-index approach can allocate tied income values differently if
    row ordering changes. Re-check the quartile counts and rates after
    any data refresh.

------------------------------------------------------------------------

## 10. Deliverables and final handover checklist

  ---------------------------------------------------------------------------------------
  Deliverable                     Purpose                 Status at note creation
  ------------------------------- ----------------------- -------------------------------
  `queries.sql`                   DDL/setup and 12        Prepared
                                  commented SQL analyses  

  `hr_attrition_analytics.pbix`   Interactive two-page    Saved as
                                  Power BI report         `hr_attrition_analytics.pbix`

  `executive_overview.png`        Page 1                  Captured in the `dashboards/`
                                  screenshot/export       folder

  `segment_explorer.png`          Page 2                  Captured in the `dashboards/`
                                  screenshot/export       folder

  `model_view.png`                Model view screenshot   Captured in the `dashboards/`
                                                          folder

  `summary.md`                    Two-page stakeholder    Prepared
                                  executive summary       

  `note.md`                       Detailed technical      This file
                                  methodology and         
                                  validation notes        
  ---------------------------------------------------------------------------------------

Before final submission:

1.  Save the Power BI project as `hr_attrition_analytics.pbix`.
2.  Clear slicers so the report screenshots show the overall dataset.
3.  Capture the Executive Overview page.
4.  Capture the Segment Explorer page.
5.  Capture the Model View.
6.  Confirm the report visuals and filters are readable.
7.  If strict rubric compliance is required, add the Department ×
    JobSatisfaction matrix to Executive Overview and the ranked segment
    table to Segment Explorer.
8.  Keep `queries.sql`, `summary.md`, and this `note.md` together with
    the PBIX and PNG exports.

------------------------------------------------------------------------

# 11. Additional Power BI implementation -- What-if analysis

## 11.1 Why a What-if parameter was added

A What-if parameter was added as a scenario-planning bonus. The purpose
is to let a report user test a hypothetical reduction in attrition for
the highest-risk combined segment found in SQL:

-   Overtime = Yes
-   Tenure = 0--2 years
-   Income quartile = Q1
-   Headcount = 45
-   Observed attritions = 32
-   Observed attrition rate = 71.11%

The parameter does not change the source employee records. It changes
only the scenario calculations displayed in the report.

## 11.2 Parameter settings

The Power BI parameter is named **Attrition Reduction (pp)**:

  Setting                                          Value
  ----------------------------- ------------------------
  Minimum                                              0
  Maximum                                             30
  Increment                                            1
  Default / example selection                         10
  Unit                            Percentage points (pp)

A single-select dropdown slicer was used so the selected scenario value
is explicit. `pp` means percentage points, not a relative percent
change. For example, reducing a 71.11% rate by 10 percentage points
gives 61.11%.

## 11.3 What-if DAX measures

### Estimated Avoided Attritions

``` dax
Estimated Avoided Attritions =
45 *
DIVIDE(
    SELECTEDVALUE(
        'Attrition Reduction (pp)'[Attrition Reduction (pp)],
        10
    ),
    100,
    0
)
```

**Why:** the model applies the selected percentage-point reduction to
the 45 employees in the identified high-risk segment. The result can be
fractional because it is an expected scenario estimate, not a count of
known individuals.

### Estimated Cost Savings

``` dax
Estimated Cost Savings =
[Estimated Avoided Attritions] * 15000
```

**Why:** the scenario assumes a replacement cost of \$15,000 for each
avoided departure. This is an illustrative assumption and should be
replaced if a verified organizational cost is available.

### Remaining Attrition Rate / Projected Attrition Rate

``` dax
Remaining Attrition Rate =
MAX(
    0,
    DIVIDE(32, 45, 0) -
    DIVIDE(
        SELECTEDVALUE(
            'Attrition Reduction (pp)'[Attrition Reduction (pp)],
            10
        ),
        100,
        0
    )
)
```

The report card was labelled **Projected Attrition Rate**. The measure
subtracts the selected percentage-point reduction from the observed
segment rate (32 / 45) and prevents a negative result with
`MAX(0, ...)`.

## 11.4 Scenario examples

  -----------------------------------------------------------------------
          Reduction Estimated avoided Estimated savings Projected segment
           selected        attritions                      attrition rate
  ----------------- ----------------- ----------------- -----------------
               0 pp              0.00               \$0            71.11%

              10 pp              4.50          \$67,500            61.11%

              20 pp              9.00         \$135,000            51.11%

              30 pp             13.50         \$202,500            41.11%
  -----------------------------------------------------------------------

These figures are outputs of a simplified scenario model. They are not a
prediction, a guarantee of savings, or evidence that a particular
intervention will achieve the selected reduction.

------------------------------------------------------------------------

# 12. Decomposition Tree -- configuration and purpose

## 12.1 Why it was added

The Decomposition Tree is an interactive visual that lets the report
user break down the total number of attritions by different employee
attributes. It was added as a bonus exploratory visual to help
investigate which segments contribute to the attrition count.

## 12.2 Configuration

-   **Analyze:** `Attritions`
-   **Explain by fields:**
    1.  `over_time`
    2.  `tenure_band`
    3.  `income_quartile`
    4.  `department`
    5.  `job_role`
    6.  `marital_status`

The field order was chosen to make it convenient to explore overtime
first, then tenure and income, followed by organizational and
demographic segmentation. The tree can be expanded in different paths;
the order is not a causal ranking.

During exploration, the user can select a **High value** split to find
the branch with the largest attrition count for the selected split
field. **Low value** finds the branch with the smallest count. These
options identify larger or smaller counts, not necessarily higher or
lower attrition rates. For rate comparisons, use the rate charts and
segment measures.

A useful path to inspect is:

`OverTime = Yes` → `tenure_band = 0-2 years` → `income_quartile = Q1`

This corresponds to the high-rate combined segment found in SQL. The
tree visual is an exploration aid; the SQL query remains the source of
the exact headcount, attrition count, and rate for that risk-profile
result.

------------------------------------------------------------------------

# 13. Interactive Tooltip page

## 13.1 Why a tooltip page was created

A dedicated report page named **Attrition Tooltip** was created to show
more detail when a user hovers over a department in the Executive
Overview department chart. This keeps the main dashboard uncluttered
while exposing additional segment-level information on demand.

## 13.2 Tooltip page configuration

-   A separate report page named `Attrition Tooltip` was created.
-   The page was configured as a tooltip page using the page information
    / tooltip settings.
-   **Allow use as tooltip** was enabled.
-   The tooltip page includes KPI cards for Headcount, Attritions, and
    Attrition Rate, plus an Attritions by Job Role chart.
-   The Job Role chart was filtered to **Top 5 by Attritions** to fit
    the compact tooltip canvas and avoid a scrollbar.

The Top N filter configuration is:

  Setting        Value
  -------------- ----------------------------------------
  Filter type    Top N
  Show items     Top 5
  By value       `Attritions` measure
  Apply filter   Apply filter after setting the measure

The page canvas was kept at the Power BI tooltip preset size. Rather
than forcing a larger canvas, the chart and text were adjusted to fit
the available tooltip area.

## 13.3 Tooltip validation

The tooltip was tested by hovering over the **Sales** department in the
Executive Overview chart. The page correctly received the department
filter context and displayed:

  KPI                Sales result
  ---------------- --------------
  Headcount                   446
  Attritions                   92
  Attrition Rate           20.63%

The Job Role chart showed Sales department roles, including Sales
Executive (57 attritions), Sales Representative (33), and Manager (2).
This confirms that the department filter context flows from the source
visual to the tooltip page.

------------------------------------------------------------------------

# 14. SQLite views -- bonus SQL objects

## 14.1 Why views were created

Three SQLite views were created to save commonly used attrition
summaries as reusable database objects. A view stores a SQL query
definition; it does not create a second copy of the employee data.

The views were created and tested in DB Browser for SQLite. They were
not imported into Power BI because the Power BI report used the CSV
import workflow.

## 14.2 View: attrition by department

``` sql
CREATE VIEW IF NOT EXISTS vw_attrition_by_department AS
SELECT
    Department,
    COUNT(*) AS Headcount,
    SUM(attrition_flag) AS Attritions,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS Attrition_Rate
FROM employees
GROUP BY Department;
```

**Purpose:** stores department-level headcount, attrition count, and
attrition rate for reuse.

Expected result:

  Department                 Headcount   Attritions   Attrition rate
  ------------------------ ----------- ------------ ----------------
  Human Resources                   63           12           19.05%
  Research & Development           961          133           13.84%
  Sales                            446           92           20.63%

## 14.3 View: attrition by overtime

``` sql
CREATE VIEW IF NOT EXISTS vw_attrition_by_overtime AS
SELECT
    OverTime,
    COUNT(*) AS Headcount,
    SUM(attrition_flag) AS Attritions,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS Attrition_Rate
FROM employees
GROUP BY OverTime;
```

**Purpose:** stores the comparison between employees who work overtime
and those who do not.

Expected result:

  OverTime     Headcount   Attritions   Attrition rate
  ---------- ----------- ------------ ----------------
  No               1,054          110           10.44%
  Yes                416          127           30.53%

## 14.4 View: attrition by job role

``` sql
CREATE VIEW IF NOT EXISTS vw_attrition_by_job_role AS
SELECT
    JobRole,
    COUNT(*) AS Headcount,
    SUM(attrition_flag) AS Attritions,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS Attrition_Rate
FROM employees
GROUP BY JobRole;
```

**Purpose:** stores the attrition summary for every job role.

Expected highest-rate results include:

  Job role                  Headcount   Attritions   Attrition rate
  ----------------------- ----------- ------------ ----------------
  Sales Representative             83           33           39.76%
  Laboratory Technician           259           62           23.94%
  Human Resources                  52           12           23.08%

## 14.5 How to query the views

``` sql
SELECT * FROM vw_attrition_by_department;
SELECT * FROM vw_attrition_by_overtime;
SELECT * FROM vw_attrition_by_job_role;
```

The views are part of `hr_analytics.db`. They are separate from the
Power BI model and therefore do not appear in Power BI Model View.

