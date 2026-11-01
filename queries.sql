SELECT COUNT(*) AS total_employees
FROM employees;

-- Q2.1: Check for duplicate employee IDs

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT EmployeeNumber) AS unique_employees
FROM employees;


-- Q2.2: Check missing values in important columns

SELECT
    SUM(CASE WHEN EmployeeNumber IS NULL THEN 1 ELSE 0 END) AS null_employee_id,
    SUM(CASE WHEN Attrition IS NULL THEN 1 ELSE 0 END) AS null_attrition,
    SUM(CASE WHEN Department IS NULL THEN 1 ELSE 0 END) AS null_department,
    SUM(CASE WHEN MonthlyIncome IS NULL THEN 1 ELSE 0 END) AS null_income,
    SUM(CASE WHEN JobRole IS NULL THEN 1 ELSE 0 END) AS null_job_role
FROM employees;


-- Q2.3: Check attrition class distribution

SELECT
    Attrition,
    COUNT(*) AS employee_count,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM employees),
        2
    ) AS percentage
FROM employees
GROUP BY Attrition;


-- Q3: KPI Summary
-- Business question:
-- How do employees who leave differ from those who stay?

SELECT
    Attrition,

    COUNT(*) AS employee_count,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM employees), 2
    ) AS employee_percentage,

    (SELECT COUNT(*)
     FROM employees
     WHERE Attrition = 'Yes') AS total_attritions,

    ROUND(
        (SELECT COUNT(*) * 100.0 FROM employees
         WHERE Attrition = 'Yes') /
        (SELECT COUNT(*) FROM employees), 2
    ) AS overall_attrition_rate,

    ROUND(AVG(MonthlyIncome), 2) AS avg_monthly_income,

    ROUND(AVG(YearsAtCompany), 2) AS avg_years_at_company,

    ROUND(AVG(JobSatisfaction), 2) AS avg_job_satisfaction

FROM employees
GROUP BY Attrition;



-- Q4: Attrition rate by Department
-- Business question:
-- Which department has the highest attrition rate?

SELECT
    Department,

    COUNT(*) AS headcount,

    SUM(
        CASE
            WHEN Attrition = 'Yes' THEN 1
            ELSE 0
        END
    ) AS attritions,

    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS attrition_rate

FROM employees

GROUP BY Department

ORDER BY attrition_rate DESC;




-- Q5: Attrition rate by JobRole
-- Business question:
-- Which job roles have the highest attrition rate?  Only include roles with at least 30 employees.

SELECT
    JobRole,

    COUNT(*) AS headcount,

    SUM(
        CASE
            WHEN Attrition = 'Yes' THEN 1
            ELSE 0
        END
    ) AS attritions,

    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS attrition_rate

FROM employees

GROUP BY JobRole

HAVING COUNT(*) >= 30

ORDER BY attrition_rate DESC;




-- Q6: Attrition by employee characteristics
-- Business question:
-- How do overtime, marital status, business travel and gender relate to employee attrition?

SELECT
    'OverTime' AS segment_type,
    OverTime AS segment,
    COUNT(*) AS headcount,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS attritions,
    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    ) AS attrition_rate
FROM employees
GROUP BY OverTime

UNION ALL

SELECT
    'MaritalStatus',
    MaritalStatus,
    COUNT(*),
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END),
    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )
FROM employees
GROUP BY MaritalStatus

UNION ALL

SELECT
    'BusinessTravel',
    BusinessTravel,
    COUNT(*),
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END),
    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )
FROM employees
GROUP BY BusinessTravel

UNION ALL

SELECT
    'Gender',
    Gender,
    COUNT(*),
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END),
    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )
FROM employees
GROUP BY Gender

ORDER BY segment_type, attrition_rate DESC;




-- Q7: Attrition rate by tenure band
-- Business question:
-- Are employees with shorter tenure more likely to leave?

SELECT
    tenure_band,
    COUNT(*) AS headcount,

    SUM(
        CASE WHEN Attrition = 'Yes' THEN 1
        ELSE 0 END
    ) AS attritions,

    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS attrition_rate

FROM (
    SELECT
        Attrition,
        CASE
            WHEN YearsAtCompany BETWEEN 0 AND 2 THEN '0-2 years'
            WHEN YearsAtCompany BETWEEN 3 AND 5 THEN '3-5 years'
            WHEN YearsAtCompany BETWEEN 6 AND 10 THEN '6-10 years'
            ELSE '11+ years'
        END AS tenure_band
    FROM employees
) AS tenure_groups

GROUP BY tenure_band

ORDER BY
    CASE tenure_band
        WHEN '0-2 years' THEN 1
        WHEN '3-5 years' THEN 2
        WHEN '6-10 years' THEN 3
        WHEN '11+ years' THEN 4
    END;


	

-- Q8: Attrition rate by income quartile
-- Business question:
-- Do employees with lower monthly incomes have higher attrition rates?

WITH income_groups AS (
    SELECT
        Attrition,
        MonthlyIncome,

        NTILE(4) OVER (
            ORDER BY MonthlyIncome
        ) AS income_quartile

    FROM employees
)

SELECT
    income_quartile,

    COUNT(*) AS headcount,

    SUM(
        CASE WHEN Attrition = 'Yes' THEN 1
        ELSE 0 END
    ) AS attritions,

    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS attrition_rate

FROM income_groups

GROUP BY income_quartile

ORDER BY income_quartile;



-- Q9: Department x JobSatisfaction Pivot
-- Business question:
-- How does attrition vary across satisfaction levels within each department?

SELECT
    Department,

    ROUND(
        100.0 * SUM(
            CASE WHEN JobSatisfaction = 1
            AND Attrition = 'Yes' THEN 1 ELSE 0 END
        ) /
        NULLIF(SUM(CASE WHEN JobSatisfaction = 1 THEN 1 ELSE 0 END), 0),
        2
    ) AS satisfaction_1,

    ROUND(
        100.0 * SUM(
            CASE WHEN JobSatisfaction = 2
            AND Attrition = 'Yes' THEN 1 ELSE 0 END
        ) /
        NULLIF(SUM(CASE WHEN JobSatisfaction = 2 THEN 1 ELSE 0 END), 0),
        2
    ) AS satisfaction_2,

    ROUND(
        100.0 * SUM(
            CASE WHEN JobSatisfaction = 3
            AND Attrition = 'Yes' THEN 1 ELSE 0 END
        ) /
        NULLIF(SUM(CASE WHEN JobSatisfaction = 3 THEN 1 ELSE 0 END), 0),
        2
    ) AS satisfaction_3,

    ROUND(
        100.0 * SUM(
            CASE WHEN JobSatisfaction = 4
            AND Attrition = 'Yes' THEN 1 ELSE 0 END
        ) /
        NULLIF(SUM(CASE WHEN JobSatisfaction = 4 THEN 1 ELSE 0 END), 0),
        2
    ) AS satisfaction_4

FROM employees

GROUP BY Department
ORDER BY Department;




-- Q10: Department x WorkLifeBalance Pivot
-- Business question:
-- How does attrition vary across work-life balance levels within each department?

SELECT
    Department,

    ROUND(
        100.0 * SUM(
            CASE WHEN WorkLifeBalance = 1
            AND Attrition = 'Yes' THEN 1 ELSE 0 END
        ) /
        NULLIF(SUM(CASE WHEN WorkLifeBalance = 1 THEN 1 ELSE 0 END), 0),
        2
    ) AS balance_1,

    ROUND(
        100.0 * SUM(
            CASE WHEN WorkLifeBalance = 2
            AND Attrition = 'Yes' THEN 1 ELSE 0 END
        ) /
        NULLIF(SUM(CASE WHEN WorkLifeBalance = 2 THEN 1 ELSE 0 END), 0),
        2
    ) AS balance_2,

    ROUND(
        100.0 * SUM(
            CASE WHEN WorkLifeBalance = 3
            AND Attrition = 'Yes' THEN 1 ELSE 0 END
        ) /
        NULLIF(SUM(CASE WHEN WorkLifeBalance = 3 THEN 1 ELSE 0 END), 0),
        2
    ) AS balance_3,

    ROUND(
        100.0 * SUM(
            CASE WHEN WorkLifeBalance = 4
            AND Attrition = 'Yes' THEN 1 ELSE 0 END
        ) /
        NULLIF(SUM(CASE WHEN WorkLifeBalance = 4 THEN 1 ELSE 0 END), 0),
        2
    ) AS balance_4

FROM employees

GROUP BY Department
ORDER BY Department;




-- Q11: Multi-factor employee risk profiles
-- Business question:
-- Which combinations of overtime, tenure and income have the highest employee attrition rates?

WITH employee_profiles AS (

    SELECT
        EmployeeNumber,
        Attrition,
        OverTime,

        CASE
            WHEN YearsAtCompany BETWEEN 0 AND 2 THEN '0-2 years'
            WHEN YearsAtCompany BETWEEN 3 AND 5 THEN '3-5 years'
            WHEN YearsAtCompany BETWEEN 6 AND 10 THEN '6-10 years'
            ELSE '11+ years'
        END AS tenure_band,

        NTILE(4) OVER (
            ORDER BY MonthlyIncome
        ) AS income_quartile

    FROM employees
),

profile_summary AS (

    SELECT
        OverTime,
        tenure_band,
        income_quartile,

        COUNT(*) AS headcount,

        SUM(
            CASE
                WHEN Attrition = 'Yes' THEN 1
                ELSE 0
            END
        ) AS attritions,

        ROUND(
            SUM(
                CASE
                    WHEN Attrition = 'Yes' THEN 1
                    ELSE 0
                END
            ) * 100.0 / COUNT(*),
            2
        ) AS attrition_rate

    FROM employee_profiles

    GROUP BY
        OverTime,
        tenure_band,
        income_quartile

    HAVING COUNT(*) >= 20
)

SELECT *
FROM profile_summary

ORDER BY attrition_rate DESC

LIMIT 3;



PRAGMA table_info(employees);



ALTER TABLE employees
ADD COLUMN attrition_flag INTEGER;



UPDATE employees
SET attrition_flag =
    CASE
        WHEN Attrition = 'Yes' THEN 1
        WHEN Attrition = 'No' THEN 0
    END;
	

SELECT
    Attrition,
    attrition_flag,
    COUNT(*) AS employee_count
FROM employees
GROUP BY Attrition, attrition_flag
ORDER BY attrition_flag;



-- Q12: Mean of numeric columns by attrition
-- Business question:
-- How do numeric employee characteristics differ
-- between employees who left and those who stayed?

SELECT
    attrition_flag,

    COUNT(*) AS employee_count,

    ROUND(AVG(Age), 2) AS avg_age,
    ROUND(AVG(DailyRate), 2) AS avg_daily_rate,
    ROUND(AVG(DistanceFromHome), 2) AS avg_distance_from_home,
    ROUND(AVG(Education), 2) AS avg_education,
    ROUND(AVG(EnvironmentSatisfaction), 2) AS avg_environment_satisfaction,
    ROUND(AVG(HourlyRate), 2) AS avg_hourly_rate,
    ROUND(AVG(JobInvolvement), 2) AS avg_job_involvement,
    ROUND(AVG(JobLevel), 2) AS avg_job_level,
    ROUND(AVG(JobSatisfaction), 2) AS avg_job_satisfaction,
    ROUND(AVG(MonthlyIncome), 2) AS avg_monthly_income,
    ROUND(AVG(MonthlyRate), 2) AS avg_monthly_rate,
    ROUND(AVG(NumCompaniesWorked), 2) AS avg_companies_worked,
    ROUND(AVG(PercentSalaryHike), 2) AS avg_salary_hike,
    ROUND(AVG(PerformanceRating), 2) AS avg_performance_rating,
    ROUND(AVG(RelationshipSatisfaction), 2) AS avg_relationship_satisfaction,
    ROUND(AVG(StockOptionLevel), 2) AS avg_stock_option_level,
    ROUND(AVG(TotalWorkingYears), 2) AS avg_total_working_years,
    ROUND(AVG(TrainingTimesLastYear), 2) AS avg_training_times,
    ROUND(AVG(WorkLifeBalance), 2) AS avg_work_life_balance,
    ROUND(AVG(YearsAtCompany), 2) AS avg_years_at_company,
    ROUND(AVG(YearsInCurrentRole), 2) AS avg_years_in_current_role,
    ROUND(AVG(YearsSinceLastPromotion), 2) AS avg_years_since_promotion,
    ROUND(AVG(YearsWithCurrManager), 2) AS avg_years_with_manager

FROM employees

GROUP BY attrition_flag

ORDER BY attrition_flag;



CREATE VIEW IF NOT EXISTS vw_attrition_by_department AS
SELECT
    Department,
    COUNT(*) AS Headcount,
    SUM(attrition_flag) AS Attritions,
    ROUND(
        100.0 * SUM(attrition_flag) / COUNT(*), 2
    ) AS Attrition_Rate
FROM employees
GROUP BY Department;

SELECT *
FROM vw_attrition_by_department;



CREATE VIEW IF NOT EXISTS vw_attrition_by_overtime AS
SELECT
    OverTime,
    COUNT(*) AS Headcount,
    SUM(attrition_flag) AS Attritions,
    ROUND(
        100.0 * SUM(attrition_flag) / COUNT(*), 2
    ) AS Attrition_Rate
FROM employees
GROUP BY OverTime;

SELECT * FROM vw_attrition_by_overtime;


CREATE VIEW IF NOT EXISTS vw_attrition_by_job_role AS
SELECT
    JobRole,
    COUNT(*) AS Headcount,
    SUM(attrition_flag) AS Attritions,
    ROUND(
        100.0 * SUM(attrition_flag) / COUNT(*), 2
    ) AS Attrition_Rate
FROM employees
GROUP BY JobRole;

SELECT * FROM vw_attrition_by_job_role
ORDER BY Attrition_Rate DESC;


SELECT * FROM vw_attrition_by_department;

SELECT * FROM vw_attrition_by_overtime;

SELECT * FROM vw_attrition_by_job_role;