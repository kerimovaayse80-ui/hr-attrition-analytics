# HR Attrition Analytics

## Executive Summary

### Project Overview

This project analyzes employee attrition using the IBM HR Analytics
Employee Attrition dataset. SQL analysis was performed in SQLite, and an
interactive report was developed in Power BI.

The dataset contains **1,470 employee records**. The analysis uses
`attrition_flag` as a binary target: `1` means the employee left and `0`
means the employee stayed.

### Overall Results

  Metric                     Result
  ------------------------ --------
  Total employees             1,470
  Employees who left            237
  Employees who stayed        1,233
  Overall attrition rate     16.12%

### Key Findings

1.  **Overtime:** Employees working overtime had a 30.53% attrition
    rate, compared with 10.44% for employees not working overtime.
2.  **Tenure:** Employees with 0--2 years at the company had a 29.82%
    attrition rate. The rate was 8.13% for employees with 11 or more
    years.
3.  **Department:** Sales had the highest department attrition rate
    (20.63%), followed by Human Resources (19.05%) and Research &
    Development (13.84%).
4.  **Job role:** Sales Representatives had a 39.76% attrition rate,
    Laboratory Technicians 23.94%, and Human Resources roles 23.08%.
    Group sizes should be considered when interpreting these rates.
5.  **Income quartile:** Q1 had a 29.35% attrition rate, compared with
    10.35% in Q4.
6.  **Marital status:** Single employees had a 25.53% attrition rate,
    married employees 12.48%, and divorced employees 10.09%.

### Highest-Risk Combined Segment

Using a minimum group size of 20 employees, the highest-risk combination
identified was:

  Segment                                              Headcount   Attritions   Attrition rate
  -------------------------------------------------- ----------- ------------ ----------------
  Overtime = Yes; tenure = 0--2 years; income = Q1            45           32           71.11%

This is a segment for further investigation; it does not prove that any
of these factors causes attrition.

### Correlation Analysis

The strongest negative correlations with the binary attrition flag were:

  Variable                  Correlation
  ----------------------- -------------
  Total Working Years            -0.171
  Job Level                      -0.169
  Years in Current Role          -0.161
  Monthly Income                 -0.160
  Age                            -0.159

All absolute correlation values were below 0.20, indicating weak linear
associations. With a binary target, these correlations can be
interpreted as point-biserial correlations. Correlation does not imply
causation.

### Recommendations

-   Review overtime frequency, workload distribution, and recovery time
    in teams with higher overtime-related attrition.
-   Strengthen onboarding, mentoring, and manager check-ins during
    employees' first two years.
-   Investigate role expectations, workload, and career development in
    high-attrition roles.
-   Review compensation competitiveness and career progression,
    particularly for employees in the lower income quartile.
-   Monitor attrition by department, job role, tenure, overtime, and
    income quartile over time.

These recommendations are areas for investigation, not proven causal
interventions.

### Power BI Deliverables

The report contains two main pages:

-   **Executive Overview:** KPI cards for headcount, attritions,
    attrition rate, average monthly income, and average tenure;
    department, job-role, and tenure charts; and a
    department-by-overtime matrix.
-   **Segment Explorer:** Interactive slicers, overtime and
    income-quartile charts, a decomposition tree, and a What-if scenario
    section.

An interactive tooltip page provides department-specific details. For
Sales, it displays 446 employees, 92 attritions, and a 20.63% attrition
rate.

### What-if Scenario

The What-if model uses the highest-risk segment (45 employees, 32
observed attritions) and an assumed replacement cost of **\$15,000 per
avoided departure**.

At a hypothetical reduction of **10 percentage points**, the model
estimates:

  Scenario output                                 Estimate
  --------------------------------------------- ----------
  Avoided attritions                                   4.5
  Estimated cost savings                          \$67,500
  Projected attrition rate within the segment       61.11%

These are scenario estimates based on assumptions, not guaranteed
savings or forecasts.

### Technical Implementation

-   **Dataset:** `employees.csv`
-   **Database:** SQLite database, `hr_analytics.db`
-   **SQL:** 12 analytical queries and three views:
    `vw_attrition_by_department`, `vw_attrition_by_overtime`, and
    `vw_attrition_by_job_role`.
-   **Power BI:** CSV import, DAX measures and calculated columns,
    slicers, charts, matrix, decomposition tree, What-if parameter, and
    tooltip page.
-   **Validation:** Selected SQL results were cross-checked against
    Power BI. Overall attrition and key overtime, department, and tenure
    results matched.

### Limitations

-   The analysis is descriptive and does not establish causation.
-   Correlations are weak and should not be interpreted as causal
    effects.
-   The What-if analysis depends on an assumed replacement cost and
    hypothetical reduction percentage.
-   SQLite views were created and tested in SQLite; they were not
    imported into the Power BI model.
-   DirectQuery was not implemented; the Power BI report uses an
    imported CSV dataset.

### Conclusion

Overtime, early tenure, department, job role, and income quartile are
useful dimensions for exploring attrition patterns in this dataset. The
Power BI report makes these patterns accessible through interactive
dashboards and hypothetical scenario analysis. The findings can guide
further investigation and retention planning, with decisions validated
against additional organizational context and future workforce data.
