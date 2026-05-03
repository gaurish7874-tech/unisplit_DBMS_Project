-- Views, not by Drake, but for easy access for common f'ns, useful for frontend

-- VIEW 1: NET BALANCE PER USER PER GROUP
-- Shows how much each person paid vs owes, and their net worth
CREATE OR REPLACE VIEW v_net_balance AS
SELECT 
    g.group_name,
    u.name,
    NVL(paid.total_paid, 0) AS total_paid, -- think of this as Coalesce f'n
    NVL(owed.total_owed, 0) AS total_owed,
    NVL(paid.total_paid, 0) - NVL(owed.total_owed, 0) AS net_balance
FROM Users u
JOIN Memberships m ON u.user_id = m.user_id
JOIN FinGroups g ON m.group_id = g.group_id
LEFT JOIN (
    SELECT paid_by, group_id, SUM(amount) AS total_paid
    FROM Expenses
    GROUP BY paid_by, group_id
) paid ON u.user_id = paid.paid_by AND g.group_id = paid.group_id
LEFT JOIN (
    SELECT es.user_id, e.group_id, SUM(es.amount_owed) AS total_owed
    FROM Expense_Split es
    JOIN Expenses e ON es.expense_id = e.expense_id
    GROUP BY es.user_id, e.group_id
) owed ON u.user_id = owed.user_id AND g.group_id = owed.group_id
ORDER BY g.group_name, net_balance DESC;

-- VIEW 2: ACTIVE LOANS WITH BORROWER AND LENDER NAMES
CREATE OR REPLACE VIEW v_active_loans AS
SELECT
    l.loan_id,
    g.group_name,
    lender.name AS lender_name,
    borrower.name AS borrower_name,
    l.amount,
    l.due_date,
    l.status,
    l.penalty_amount,
    CASE 
        WHEN l.due_date < SYSDATE AND l.status != 'repaid' 
        THEN ROUND(SYSDATE - l.due_date) 
        ELSE 0 
    END AS days_overdue
FROM Loans l
JOIN FinGroups g ON l.group_id = g.group_id
JOIN Users lender ON l.lender_id = lender.user_id
JOIN Users borrower ON l.borrower_id = borrower.user_id;

-- VIEW 3: GROUP EXPENSE SUMMARY
CREATE OR REPLACE VIEW v_group_summary AS
SELECT
    g.group_name,
    COUNT(DISTINCT m.user_id) AS total_members,
    COUNT(DISTINCT e.expense_id) AS total_expenses,
    NVL(SUM(e.amount), 0) AS total_spent,
    NVL(ROUND(AVG(e.amount), 2), 0) AS avg_expense
FROM FinGroups g
LEFT JOIN Memberships m ON g.group_id = m.group_id
LEFT JOIN Expenses e ON g.group_id = e.group_id
GROUP BY g.group_id, g.group_name;