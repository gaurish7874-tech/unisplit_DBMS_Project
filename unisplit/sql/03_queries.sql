-- interesting operations we can perform/insights from this relational DBMS project
-- feel free to add on more interesting stuff

-- expense details
SELECT 
    e.expense_id,
    e.title,
    e.amount,
    u.name AS paid_by,
    g.group_name,
    e.expense_date
FROM Expenses e
JOIN Users u ON e.paid_by = u.user_id
JOIN FinGroups g ON e.group_id = g.group_id
ORDER BY e.expense_date DESC;

-- expenditure in a group
SELECT 
    g.group_name,
    COUNT(e.expense_id) AS num_expenses,
    SUM(e.amount) AS total_spent,
    ROUND(AVG(e.amount), 2) AS avg_expense
FROM FinGroups g
JOIN Expenses e ON g.group_id = e.group_id
GROUP BY g.group_id, g.group_name
ORDER BY total_spent DESC;

-- individual contribution in groups
SELECT 
    g.group_name,
    u.name,
    SUM(e.amount) AS total_paid,
    COUNT(e.expense_id) AS num_expenses_paid
FROM Expenses e
JOIN Users u ON e.paid_by = u.user_id
JOIN FinGroups g ON e.group_id = g.group_id
GROUP BY g.group_id, g.group_name, u.user_id, u.name
ORDER BY g.group_name, total_paid DESC;

-- group meta data
SELECT 
    g.group_name,
    u.name,
    m.role,
    m.status,
    m.joined_at
FROM Memberships m
JOIN Users u ON m.user_id = u.user_id
JOIN FinGroups g ON m.group_id = g.group_id
ORDER BY g.group_name, m.role ASC; -- admins up, just a style choice

-- people may be in multiple groups
SELECT 
    u.name,
    COUNT(m.group_id) AS num_groups
FROM Users u
JOIN Memberships m ON u.user_id = m.user_id
GROUP BY u.user_id, u.name
HAVING COUNT(m.group_id) > 1;

-- users who have never paid any expense, freeloaders
SELECT name FROM Users
WHERE user_id NOT IN (SELECT DISTINCT paid_by FROM Expenses);

-- groups with total spending over X Amount
SELECT g.group_name, SUM(e.amount) AS total
FROM FinGroups g
JOIN Expenses e ON g.group_id = e.group_id
GROUP BY g.group_id, g.group_name
HAVING SUM(e.amount) > 10000;

-- all overdue loans with days overdue
SELECT 
    l.loan_id,
    lender.name AS lender,
    borrower.name AS borrower,
    l.amount,
    ROUND(SYSDATE - l.due_date) AS days_overdue
FROM Loans l
JOIN Users lender ON l.lender_id = lender.user_id
JOIN Users borrower ON l.borrower_id = borrower.user_id
WHERE l.status = 'overdue';