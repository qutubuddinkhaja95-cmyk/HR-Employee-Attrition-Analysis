CREATE DATABASE IF NOT EXISTS hr_analytics;
USE hr_analytics;

SHOW TABLES FROM hr_analytics;
RENAME TABLE `hr-employee-attrition` TO employee_attrition;
show tables;

-- Display the first 10 rows from the table.
SELECT * FROM employee_attrition LIMIT 10;

-- Find the total number of employees in the company.
SELECT COUNT(*) FROM employee_attrition;

-- List all unique departments.
SELECT DISTINCT Department FROM employee_attrition;

-- Show how many employees have left the company and how many are still working.
SELECT Attrition, COUNT(*) AS employee_count
FROM employee_attrition
GROUP BY Attrition;

-- Retrieve the list of employees who work overtime.
SELECT * FROM employee_attrition
WHERE OverTime = 'Yes';

-- Find the average monthly income of all employees.
SELECT ROUND(AVG(MonthlyIncome), 2) AS avg_monthly_income
FROM employee_attrition;

-- Identify employees whose number of companies worked is missing (NULL).
SELECT * FROM employee_attrition
WHERE NumCompaniesWorked IS NULL;

-- Find the employee(s) with the maximum monthly income.
SELECT * FROM employee_attrition
WHERE MonthlyIncome = (SELECT MAX(MonthlyIncome) FROM employee_attrition);

-- Count the number of employees by gender.
SELECT Gender, COUNT(*) AS employee_count
FROM employee_attrition
GROUP BY Gender;

--  List all employees who have just joined (YearsAtCompany = 0).
SELECT * FROM employee_attrition
WHERE YearsAtCompany = 0;

--  Calculate the attrition rate (%) by department.
SELECT
    Department,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS leavers,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM employee_attrition
GROUP BY Department;

--  List the top 10 employees with the highest total working years.
SELECT * FROM employee_attrition
ORDER BY TotalWorkingYears DESC
LIMIT 10;

--  Group employees into tenure categories (<1yr, 1–3yr, 4–6yr, 7+yr) and count employees in each.
SELECT
    CASE
        WHEN YearsAtCompany < 1 THEN '<1yr'
        WHEN YearsAtCompany BETWEEN 1 AND 3 THEN '1-3yr'
        WHEN YearsAtCompany BETWEEN 4 AND 6 THEN '4-6yr'
        ELSE '7+yr'
    END AS tenure_category,
    COUNT(*) AS employee_count
FROM employee_attrition
GROUP BY tenure_category
ORDER BY FIELD(tenure_category, '<1yr', '1-3yr', '4-6yr', '7+yr');
 

-- Find the average monthly income by job level and attrition status.
SELECT
    JobLevel,
    Attrition,
    ROUND(AVG(MonthlyIncome), 2) AS avg_monthly_income
FROM employee_attrition
GROUP BY JobLevel, Attrition
ORDER BY JobLevel, Attrition;

--  Identify the top 5 job roles with the highest number of employees who left.
SELECT JobRole, COUNT(*) AS leavers
FROM employee_attrition
WHERE Attrition = 'Yes'
GROUP BY JobRole
ORDER BY leavers DESC
LIMIT 5;


--  List employees who left the company within their first year.
SELECT * FROM employee_attrition
WHERE Attrition = 'Yes' AND YearsAtCompany < 1;

--  Determine the median monthly income of all employees.
SELECT AVG(MonthlyIncome) AS median_monthly_income
FROM (
    SELECT
        MonthlyIncome,
        ROW_NUMBER() OVER (ORDER BY MonthlyIncome) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM employee_attrition
) ranked
WHERE row_num IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2));

--  Calculate each employee’s approximate new monthly compensation after applying their salary hike percentage.
SELECT
    EmployeeNumber,
    MonthlyIncome,
    PercentSalaryHike,
    ROUND(MonthlyIncome * (1 + PercentSalaryHike / 100), 2) AS new_monthly_income
FROM employee_attrition;

-- Count employees grouped by overtime status and attrition.
SELECT
    OverTime,
    Attrition,
    COUNT(*) AS employee_count
FROM employee_attrition
GROUP BY OverTime, Attrition;

--  Display the top 10 employees who attended the most training sessions last year.
SELECT * FROM employee_attrition
ORDER BY TrainingTimesLastYear DESC
LIMIT 10;

--  Rank employees by total working years (most experienced = rank 1).
SELECT
    EmployeeNumber,
    TotalWorkingYears,
    RANK() OVER (ORDER BY TotalWorkingYears DESC) AS experience_rank
FROM employee_attrition;

--  For each department, find employees whose monthly income is in the top 25% of that department.
SELECT * FROM (
    SELECT
        *,
        PERCENT_RANK() OVER (PARTITION BY Department ORDER BY MonthlyIncome DESC) AS pct_rank
    FROM employee_attrition
) ranked
WHERE pct_rank <= 0.25;

-- Divide employees into 10 income deciles and find attrition rate for each decile.
SELECT
    income_decile,
    COUNT(*) AS employee_count,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM (
    SELECT
        *,
        NTILE(10) OVER (ORDER BY MonthlyIncome) AS income_decile
    FROM employee_attrition
) deciled
GROUP BY income_decile
ORDER BY income_decile;

-- Create a simple risk score based on tenure, performance, overtime, and work-life balance and list the top 50 high-risk employees.
SELECT
    EmployeeNumber,
    YearsAtCompany,
    PerformanceRating,
    OverTime,
    WorkLifeBalance,
    (
        (10 - LEAST(YearsAtCompany, 10)) * 1        -- less tenure -> more risk
        + (5 - PerformanceRating) * 2                -- lower performance -> more risk
        + (CASE WHEN OverTime = 'Yes' THEN 5 ELSE 0 END)  -- overtime -> more risk
        + (5 - WorkLifeBalance) * 2                  -- poor work-life balance -> more risk
    ) AS risk_score
FROM employee_attrition
ORDER BY risk_score DESC
LIMIT 50;

-- Create a summary view showing, for each department and job level: total employees, number of leavers, attrition rate, and average monthly income.
CREATE OR REPLACE VIEW dept_joblevel_summary AS
SELECT
    Department,
    JobLevel,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS leavers,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS attrition_rate_pct,
    ROUND(AVG(MonthlyIncome), 2) AS avg_monthly_income
FROM employee_attrition
GROUP BY Department, JobLevel;
 
-- View the summary:
SELECT * FROM dept_joblevel_summary
ORDER BY Department, JobLevel;







