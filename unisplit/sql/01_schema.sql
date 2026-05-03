-- schema
-- oracle-apex : run this w/ drop all tables in reverse for easy insertion of data
-- users
CREATE TABLE Users (
    user_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- auto increm.
    name    VARCHAR2(100) NOT NULL,
    email   VARCHAR2(150) UNIQUE NOT NULL,
    phone   VARCHAR2(15),
    created_at DATE DEFAULT SYSDATE
);

-- groups of users for some activity, etc.
CREATE TABLE FinGroups (
    group_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_name  VARCHAR2(100) NOT NULL,
    description     VARCHAR2(500),
    created_by      NUMBER NOT NULL,
    created_at      DATE DEFAULT SYSDATE,
    CONSTRAINT fk_group_creator -- real user created this group
        FOREIGN KEY (created_by) REFERENCES Users(user_id)
);
-- people joining groups have membership
CREATE TABLE Memberships (
    membership_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     NUMBER NOT NULL REFERENCES Users(user_id),
    group_id    NUMBER NOT NULL REFERENCES FinGroups(group_id),
    role    VARCHAR2(20) DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    joined_at   DATE DEFAULT SYSDATE,
    status  VARCHAR2(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    CONSTRAINT uq_mem_user_group UNIQUE (user_id, group_id) -- can't join same group TWICE!
);
-- financial events
CREATE TABLE Expenses (
    expense_id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_id    NUMBER NOT NULL REFERENCES FinGroups(group_id),
    paid_by     NUMBER NOT NULL REFERENCES Users(user_id),
    title       VARCHAR2(200) NOT NULL,
    amount      NUMBER(10, 2) NOT NULL,
    expense_date    DATE DEFAULT SYSDATE,
    split_type      VARCHAR2(20) DEFAULT 'equal' CHECK (split_type IN ('equal', 'custom')),
    CONSTRAINT chk_exp_amount CHECK (amount > 0) -- check this!
);
-- cash/debt distribution details, logical handling managed in pl sql
CREATE TABLE Expense_Split (
    split_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    expense_id      NUMBER NOT NULL REFERENCES Expenses(expense_id),
    user_id     NUMBER NOT NULL REFERENCES Users(user_id),
    amount_owed     NUMBER(10,2) NOT NULL,
    is_settled      VARCHAR2(5) DEFAULT 'N' CHECK (is_settled IN ('Y','N')),
    CONSTRAINT uq_split UNIQUE (expense_id, user_id), -- very important! think why
    CONSTRAINT chk_amount_owed CHECK (amount_owed > 0)
);

-- people within groups can loan money to friends
CREATE TABLE Loans (
    loan_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_id        NUMBER NOT NULL REFERENCES FinGroups(group_id), -- micro credits! within group
    lender_id       NUMBER NOT NULL REFERENCES Users(user_id), -- these are one to one
    borrower_id     NUMBER NOT NULL REFERENCES Users(user_id), -- expenses are split though
    amount      NUMBER(10,2) NOT NULL,
    due_date        DATE NOT NULL, -- for accountability
    status      VARCHAR2(20) DEFAULT 'active' CHECK (status IN ('active','repaid','overdue')),
    penalty_amount  NUMBER(10,2) DEFAULT 0,
    created_at      DATE DEFAULT SYSDATE,
    CONSTRAINT chk_loan_amount CHECK (amount > 0),
    CONSTRAINT chk_no_self_loan CHECK (lender_id != borrower_id) -- logical stuff checks
);

-- remits, account for multiple debts/expenses etc per payment
CREATE TABLE Settlements (
    settlement_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_id        NUMBER NOT NULL REFERENCES FinGroups(group_id),
    payer_id        NUMBER NOT NULL REFERENCES Users(user_id),
    payee_id        NUMBER NOT NULL REFERENCES Users(user_id),
    amount      NUMBER(10,2) NOT NULL,
    settlement_date DATE DEFAULT SYSDATE,
    note        VARCHAR2(500), -- any message etc etc
    CONSTRAINT chk_settlement_amount CHECK (amount > 0),
    CONSTRAINT chk_no_self_settle CHECK (payer_id != payee_id) -- no loopholes
);

-- for the IRS
CREATE TABLE Audit_Log (
    log_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    action_type     VARCHAR2(50) NOT NULL,
    table_name      VARCHAR2(50) NOT NULL,
    record_id       NUMBER,
    action_by       NUMBER REFERENCES Users(user_id),
    action_date     DATE DEFAULT SYSDATE,
    details     VARCHAR2(1000)
);