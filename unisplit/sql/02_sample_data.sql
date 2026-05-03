-- UNISPLIT SAMPLE DATA
-- nice references if you can catch them

-- users
INSERT INTO Users (name, email, phone) VALUES ('Frank Underwood', 'frank.u@unisplit.com', '9811000001');
INSERT INTO Users (name, email, phone) VALUES ('Claire Underwood', 'claire.u@unisplit.com', '9811000002');
INSERT INTO Users (name, email, phone) VALUES ('Doug Stamper', 'doug.s@unisplit.com', '9811000003');
INSERT INTO Users (name, email, phone) VALUES ('Zoe Barnes', 'zoe.b@unisplit.com', '9811000004');
INSERT INTO Users (name, email, phone) VALUES ('Kate Wyler', 'kate.w@unisplit.com', '9811000005');
INSERT INTO Users (name, email, phone) VALUES ('Hal Wyler', 'hal.w@unisplit.com', '9811000006');
INSERT INTO Users (name, email, phone) VALUES ('Raymond Tusk', 'ray.t@unisplit.com', '9811000007');
COMMIT;

-- groups — Frank creates DC ones, Kate runs the London op
INSERT INTO FinGroups (group_name, description, created_by) VALUES ('DC Power Lunch', 'Weekly political strategy dinners, Frank pays — usually', 1);
INSERT INTO FinGroups (group_name, description, created_by) VALUES ('Underwood Campaign', 'Campaign trail expenses — hotels, flights, bribes', 1);
INSERT INTO FinGroups (group_name, description, created_by) VALUES ('London Diplomatic Mission', 'Kate managing embassy expenses abroad', 5);
COMMIT;

-- memberships
-- DC Lunch: Frank, Claire, Doug, Zoe
INSERT INTO Memberships (user_id, group_id, role) VALUES (1, 1, 'admin');
INSERT INTO Memberships (user_id, group_id, role) VALUES (2, 1, 'member');
INSERT INTO Memberships (user_id, group_id, role) VALUES (3, 1, 'member');
INSERT INTO Memberships (user_id, group_id, role) VALUES (4, 1, 'member');
-- Underwood Campaign: Frank, Claire, Doug, Raymond
INSERT INTO Memberships (user_id, group_id, role) VALUES (1, 2, 'admin');
INSERT INTO Memberships (user_id, group_id, role) VALUES (2, 2, 'member');
INSERT INTO Memberships (user_id, group_id, role) VALUES (3, 2, 'member');
INSERT INTO Memberships (user_id, group_id, role) VALUES (7, 2, 'member');
-- London Mission: Kate, Hal, Claire (she gets everywhere)
INSERT INTO Memberships (user_id, group_id, role) VALUES (5, 3, 'admin');
INSERT INTO Memberships (user_id, group_id, role) VALUES (6, 3, 'member');
INSERT INTO Memberships (user_id, group_id, role) VALUES (2, 3, 'member');
COMMIT;

-- expenses
-- DC Lunch
INSERT INTO Expenses (group_id, paid_by, title, amount, split_type) VALUES (1, 1, 'Dinner at Fontaine', 9200, 'equal');
INSERT INTO Expenses (group_id, paid_by, title, amount, split_type) VALUES (1, 3, 'Whiskey and cigars', 3600, 'equal');
INSERT INTO Expenses (group_id, paid_by, title, amount, split_type) VALUES (1, 4, 'Cab charges', 1200, 'equal');
-- Underwood Campaign
INSERT INTO Expenses (group_id, paid_by, title, amount, split_type) VALUES (2, 1, 'Hotel - Iowa caucus', 18000, 'equal');
INSERT INTO Expenses (group_id, paid_by, title, amount, split_type) VALUES (2, 7, 'Private jet fuel', 45000, 'equal');
INSERT INTO Expenses (group_id, paid_by, title, amount, split_type) VALUES (2, 2, 'Press conference catering', 8400, 'equal');
-- London Diplomatic Mission
INSERT INTO Expenses (group_id, paid_by, title, amount, split_type) VALUES (3, 5, 'Embassy reception dinner', 22000, 'equal');
INSERT INTO Expenses (group_id, paid_by, title, amount, split_type) VALUES (3, 6, 'Hotel - Mayfair', 31500, 'equal');
INSERT INTO Expenses (group_id, paid_by, title, amount, split_type) VALUES (3, 2, 'Diplomatic gifts', 9000, 'equal');
COMMIT;

-- splits
-- DC Power Lunch (4 members)
-- Dinner at Fontaine: 9200/4 = 2300
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (1, 1, 2300);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (1, 2, 2300);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (1, 3, 2300);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (1, 4, 2300);
-- Whiskey and cigars: 3600/4 = 900
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (2, 1, 900);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (2, 2, 900);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (2, 3, 900);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (2, 4, 900);
-- Cab charges: 1200/4 = 300
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (3, 1, 300);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (3, 2, 300);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (3, 3, 300);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (3, 4, 300);
COMMIT;

-- Underwood Campaign (4 members)
-- Hotel Iowa: 18000/4 = 4500
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (4, 1, 4500);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (4, 2, 4500);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (4, 3, 4500);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (4, 7, 4500);
-- Private jet fuel: 45000/4 = 11250
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (5, 1, 11250);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (5, 2, 11250);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (5, 3, 11250);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (5, 7, 11250);
-- Press conference catering: 8400/4 = 2100
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (6, 1, 2100);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (6, 2, 2100);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (6, 3, 2100);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (6, 7, 2100);
COMMIT;

-- London Diplomatic Mission (3 members)
-- Embassy reception: 22000/3 = 7333.33 (extra on Claire)
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (7, 5, 7333.33);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (7, 6, 7333.33);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (7, 2, 7333.34);
-- Hotel Mayfair: 31500/3 = 10500
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (8, 5, 10500);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (8, 6, 10500);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (8, 2, 10500);
-- Diplomatic gifts: 9000/3 = 3000
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (9, 5, 3000);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (9, 6, 3000);
INSERT INTO Expense_Split (expense_id, user_id, amount_owed) VALUES (9, 2, 3000);
COMMIT;

-- loans — two overdue, one active
-- Doug borrowed from Frank for "security"
INSERT INTO Loans (group_id, lender_id, borrower_id, amount, due_date, status) VALUES (1, 1, 3, 5000, SYSDATE - 7, 'overdue');
-- Raymond lent Claire campaign money 
INSERT INTO Loans (group_id, lender_id, borrower_id, amount, due_date, status) VALUES (2, 7, 2, 12000, SYSDATE + 14, 'active');
-- Hal quietly upgraded his London hotel on Kate's tab, overdue
INSERT INTO Loans (group_id, lender_id, borrower_id, amount, due_date, status) VALUES (3, 5, 6, 8500, SYSDATE - 3, 'overdue');
COMMIT;

-- settlements
-- Zoe paid Frank back for DC dinners
INSERT INTO Settlements (group_id, payer_id, payee_id, amount, note) VALUES (1, 4, 1, 3500, 'Zoe settling DC Power Lunch dues');
-- Doug made a token gesture, Frank not impressed
INSERT INTO Settlements (group_id, payer_id, payee_id, amount, note) VALUES (1, 3, 1, 2000, 'Doug partial payment — Frank not impressed');
COMMIT;