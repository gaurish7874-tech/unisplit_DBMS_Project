-- interesting operations we can perform/insights from this relational DBMS project
-- feel free to add on more interesting stuff

-- Query 1 — Full Expense Details with Payer and Group 
SELECT e.expense_id, e.title, e.amount, 
       u.name AS paid_by, g.group_name, e.expense_date 
FROM Expenses e 
JOIN Users u ON e.paid_by = u.user_id 
JOIN FinGroups g ON e.group_id = g.group_id 
ORDER BY e.expense_date DESC; 
 
-- Query 2 — Group Expenditure Summary 
SELECT g.group_name, COUNT(e.expense_id) AS num_expenses, 
       SUM(e.amount) AS total_spent, ROUND(AVG(e.amount),2) AS avg_expense 
FROM FinGroups g JOIN Expenses e ON g.group_id = e.group_id 
GROUP BY g.group_id, g.group_name ORDER BY total_spent DESC; 
 
-- Query 3 — Users Who Never Paid an Expense (Freeloaders) 
SELECT name FROM Users 
WHERE user_id NOT IN (SELECT DISTINCT paid_by FROM Expenses); 
 
-- Query 4 — Overdue Loans with Days Overdue 
SELECT l.loan_id, lender.name AS lender, borrower.name AS borrower, 
       l.amount, ROUND(SYSDATE - l.due_date) AS days_overdue 
FROM Loans l 
JOIN Users lender ON l.lender_id = lender.user_id 
JOIN Users borrower ON l.borrower_id = borrower.user_id 
WHERE l.status = 'overdue'; 
 
-- Query 5 — Groups with Total Spending Above 10,000 
SELECT g.group_name, SUM(e.amount) AS total 
FROM FinGroups g JOIN Expenses e ON g.group_id = e.group_id 
GROUP BY g.group_id, g.group_name HAVING SUM(e.amount) > 10000; 
 
-- Query 6 — Users in Multiple Groups 
SELECT u.name, COUNT(m.group_id) AS num_groups 
FROM Users u JOIN Memberships m ON u.user_id = m.user_id 
GROUP BY u.user_id, u.name HAVING COUNT(m.group_id) > 1; 
-- Query 9 — Unsettled Splits (Outstanding Obligations) 
SELECT u.name AS user_name, g.group_name,        e.title AS expense_title,        es.amount_owed, es.is_settled 
FROM Expense_Split es 
JOIN Users u ON es.user_id = u.user_id 
JOIN Expenses e ON es.expense_id = e.expense_id 
JOIN FinGroups g ON e.group_id = g.group_id 
WHERE es.is_settled = 'N' 
ORDER BY g.group_name, es.amount_owed DESC; 
-- Query 10 — Total Unsettled Amount Per User (All Groups) 
SELECT u.name, 
       COUNT(es.split_id) AS unsettled_splits, 
       SUM(es.amount_owed) AS total_outstanding 
FROM Users u 
JOIN Expense_Split es ON u.user_id = es.user_id 
WHERE es.is_settled = 'N' 
GROUP BY u.user_id, u.name 
ORDER BY total_outstanding DESC; 
-- Query 11 — Top Spenders Across All Groups (RANK Window Function) 
SELECT u.name, 
       COUNT(e.expense_id) AS expenses_paid, 
       SUM(e.amount) AS total_paid_out, 
       RANK() OVER (ORDER BY SUM(e.amount) DESC) AS spender_rank 
FROM Users u 
JOIN Expenses e ON u.user_id = e.paid_by 
GROUP BY u.user_id, u.name 
ORDER BY spender_rank; 
-- Query 12 — Settlement History with Full Details 
SELECT s.settlement_id, g.group_name,        payer.name AS paid_by, payee.name AS paid_to,        s.amount, s.settlement_date, s.note 
FROM Settlements s 
JOIN FinGroups g ON s.group_id = g.group_id 
JOIN Users payer ON s.payer_id = payer.user_id 
JOIN Users payee ON s.payee_id = payee.user_id 
ORDER BY s.settlement_date DESC; 
-- Query 13 — Loan Portfolio Summary by Status 
SELECT l.status, 
       COUNT(*) AS loan_count, 
       SUM(l.amount) AS total_amount, 
       SUM(l.penalty_amount) AS total_penalties 
FROM Loans l 
GROUP BY l.status 
ORDER BY loan_count DESC; 
 
-- Query 14 — Net Debtors (Subquery: Owed > Paid) SELECT name, total_paid, total_owed, 
       (total_owed - total_paid) AS shortfall 
FROM ( 
    SELECT u.name, 
           NVL((SELECT SUM(amount) FROM Expenses 
                WHERE paid_by = u.user_id), 0) AS total_paid, 
           NVL((SELECT SUM(es.amount_owed) 
                FROM Expense_Split es 
                WHERE es.user_id = u.user_id), 0) AS total_owed 
    FROM Users u 
) 
WHERE total_owed > total_paid 
ORDER BY shortfall DESC; 
-- Query 15 — Full Expense Split Detail with Settlement Status 
SELECT g.group_name, e.title, 
       e.amount AS total_expense,        payer.name AS paid_by,        u.name AS owes_name,        es.amount_owed,        CASE es.is_settled 
           WHEN 'Y' THEN 'Settled' 
           ELSE 'Pending' END AS status 
FROM Expense_Split es 
JOIN Expenses e ON es.expense_id = e.expense_id 
JOIN FinGroups g ON e.group_id = g.group_id 
JOIN Users u ON es.user_id = u.user_id 
JOIN Users payer ON e.paid_by = payer.user_id 
ORDER BY g.group_name, e.expense_date DESC; 
-- Query 16 — Cross-Group Totals Using ROLLUP 
SELECT 
    NVL(g.group_name, '** ALL GROUPS **') AS group_name, 
    NVL(u.name, '** ALL USERS **') AS user_name, 
    SUM(e.amount) AS total_paid FROM Expenses e 
JOIN Users u ON e.paid_by = u.user_id 
JOIN FinGroups g ON e.group_id = g.group_id 
GROUP BY ROLLUP(g.group_name, u.name) 
ORDER BY g.group_name NULLS LAST, total_paid DESC NULLS LAST; 

-- Query 17 — Recent Audit Log Entries (Last 20)
 SELECT al.log_id, al.action_type, al.table_name,        al.record_id, u.name AS action_by,        al.action_date, al.details 
FROM Audit_Log al 
LEFT JOIN Users u ON al.action_by = u.user_id 
ORDER BY al.action_date DESC 
FETCH FIRST 20 ROWS ONLY; 
 
-- Query 18 — Admin Contribution Percentage Per Group 
SELECT g.group_name, admin_user.name AS admin_name,        COALESCE(SUM(e.amount), 0) AS admin_total_paid, 
       gs.total_spent AS group_total,        ROUND(COALESCE(SUM(e.amount), 0) 
           / NULLIF(gs.total_spent, 0) * 100, 1) AS admin_pct 
FROM FinGroups g 
JOIN Memberships m ON g.group_id = m.group_id 
    AND m.role = 'admin' 
JOIN Users admin_user ON m.user_id = admin_user.user_id 
LEFT JOIN Expenses e ON g.group_id = e.group_id 
    AND e.paid_by = admin_user.user_id 
JOIN (SELECT group_id, SUM(amount) AS total_spent 
      FROM Expenses GROUP BY group_id) gs 
    ON g.group_id = gs.group_id GROUP BY g.group_id, g.group_name,          admin_user.name, gs.total_spent ORDER BY admin_pct DESC;