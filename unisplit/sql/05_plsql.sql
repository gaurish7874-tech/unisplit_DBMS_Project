-- pl sql part handling main logic, most important part
-- particularly cuz of triggers

CREATE OR REPLACE PROCEDURE add_expense (
    p_group_id    IN NUMBER,
    p_paid_by     IN NUMBER,
    p_title       IN VARCHAR2,
    p_amount      IN NUMBER
)
AS
    v_member_count  NUMBER;
    v_split_amount  NUMBER;
    v_expense_id    NUMBER;
    
    CURSOR c_members IS
        SELECT user_id 
        FROM Memberships 
        WHERE group_id = p_group_id 
        AND status = 'active';
BEGIN
    -- Count active members in group
    SELECT COUNT(*) INTO v_member_count
    FROM Memberships
    WHERE group_id = p_group_id AND status = 'active';
    
    -- Validate
    IF v_member_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'No active members in this group');
    END IF;
    
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Amount must be positive');
    END IF;
    
    -- Calculate equal split
    v_split_amount := ROUND(p_amount / v_member_count, 2);
    
    -- Insert expense
    INSERT INTO Expenses (group_id, paid_by, title, amount, split_type)
    VALUES (p_group_id, p_paid_by, p_title, p_amount, 'equal')
    RETURNING expense_id INTO v_expense_id;
    
    -- Insert split for each member using cursor
    FOR member IN c_members LOOP
        INSERT INTO Expense_Split (expense_id, user_id, amount_owed)
        VALUES (v_expense_id, member.user_id, v_split_amount);
    END LOOP;
    
    -- Log the action
    INSERT INTO Audit_Log (action_type, table_name, record_id, action_by, details)
    VALUES ('INSERT', 'EXPENSES', v_expense_id, p_paid_by, 
            'Expense added: ' || p_title || ', Amount: ' || p_amount);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Expense added successfully. ID: ' || v_expense_id);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'Error adding expense: ' || SQLERRM);
END;
/
-- procedure 2
CREATE OR REPLACE PROCEDURE settle_debt (
    p_group_id  IN NUMBER,
    p_payer_id  IN NUMBER,
    p_payee_id  IN NUMBER,
    p_amount    IN NUMBER,
    p_note      IN VARCHAR2 DEFAULT NULL
)
AS
    v_settlement_id NUMBER;
BEGIN
    -- Validate amount
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Settlement amount must be positive');
    END IF;

    -- Validate payer and payee are different
    IF p_payer_id = p_payee_id THEN
        RAISE_APPLICATION_ERROR(-20004, 'Payer and payee cannot be the same');
    END IF;

    -- Insert settlement
    INSERT INTO Settlements (group_id, payer_id, payee_id, amount, note)
    VALUES (p_group_id, p_payer_id, p_payee_id, p_amount, p_note)
    RETURNING settlement_id INTO v_settlement_id;

    -- Mark related splits as settled
    UPDATE Expense_Split
    SET is_settled = 'Y'
    WHERE user_id = p_payer_id
    AND expense_id IN (
        SELECT expense_id FROM Expenses WHERE group_id = p_group_id
    )
    AND is_settled = 'N';

    -- Log the action
    INSERT INTO Audit_Log (action_type, table_name, record_id, action_by, details)
    VALUES ('SETTLEMENT', 'SETTLEMENTS', v_settlement_id, p_payer_id,
            'Settlement of ' || p_amount || ' made to user ' || p_payee_id);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Settlement recorded. ID: ' || v_settlement_id);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'Error recording settlement: ' || SQLERRM);
END;
/

---
-- FUNCTION 1: GET NET BALANCE FOR A USER IN A GROUP
CREATE OR REPLACE FUNCTION get_net_balance (
    p_user_id   IN NUMBER,
    p_group_id  IN NUMBER
) RETURN NUMBER
AS
    v_total_paid    NUMBER := 0;
    v_total_owed    NUMBER := 0;
BEGIN
    -- How much did this user pay
    SELECT NVL(SUM(amount), 0) INTO v_total_paid
    FROM Expenses
    WHERE paid_by = p_user_id AND group_id = p_group_id;

    -- How much does this user owe
    SELECT NVL(SUM(es.amount_owed), 0) INTO v_total_owed
    FROM Expense_Split es
    JOIN Expenses e ON es.expense_id = e.expense_id
    WHERE es.user_id = p_user_id AND e.group_id = p_group_id;

    RETURN v_total_paid - v_total_owed;

EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
/

-- FUNCTION 2: CALCULATE PENALTY FOR OVERDUE LOAN
CREATE OR REPLACE FUNCTION calculate_penalty (
    p_loan_id IN NUMBER
) RETURN NUMBER
AS
    v_due_date      DATE;
    v_amount        NUMBER;
    v_status        VARCHAR2(20);
    v_days_overdue  NUMBER;
    v_penalty       NUMBER := 0;
    v_penalty_rate  NUMBER := 0.02; -- say it's 2% per day
BEGIN
    SELECT due_date, amount, status
    INTO v_due_date, v_amount, v_status
    FROM Loans
    WHERE loan_id = p_loan_id;

    IF v_status = 'overdue' AND SYSDATE > v_due_date THEN
        v_days_overdue := ROUND(SYSDATE - v_due_date);
        v_penalty := ROUND(v_amount * v_penalty_rate * v_days_overdue, 2);
    END IF;

    RETURN v_penalty;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20005, 'Loan not found: ' || p_loan_id);
    WHEN OTHERS THEN
        RETURN NULL;
END;
/

--- triggers
-- TRIGGER 1: AUTO AUDIT LOG ON NEW EXPENSE
CREATE OR REPLACE TRIGGER trg_audit_expense
AFTER INSERT ON Expenses
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (action_type, table_name, record_id, action_by, details)
    VALUES (
        'INSERT',
        'EXPENSES',
        :NEW.expense_id,
        :NEW.paid_by,
        'New expense: ' || :NEW.title || ', Amount: ' || :NEW.amount || 
        ', Group: ' || :NEW.group_id
    );
END;
/

-- TRIGGER 2: AUTO MARK LOAN AS OVERDUE
CREATE OR REPLACE TRIGGER trg_loan_status
BEFORE INSERT OR UPDATE ON Loans
FOR EACH ROW
BEGIN
    IF :NEW.due_date < SYSDATE AND :NEW.status = 'active' THEN
        :NEW.status := 'overdue';
    END IF;
END;
/

-- TRIGGER 3: AUTO UPDATE PENALTY ON OVERDUE LOAN
CREATE OR REPLACE TRIGGER trg_penalty_update
BEFORE UPDATE ON Loans
FOR EACH ROW
WHEN (NEW.status = 'overdue')
BEGIN
    :NEW.penalty_amount := calculate_penalty(:NEW.loan_id);
END;
/
--- cursor stuff again
-- CURSOR: PROCESS ALL OVERDUE LOANS AND UPDATE PENALTIES
CREATE OR REPLACE PROCEDURE process_overdue_loans
AS
    -- Explicit cursor declaration
    CURSOR c_overdue_loans IS
        SELECT loan_id, borrower_id, amount, due_date, penalty_amount
        FROM Loans
        WHERE status = 'overdue';

    v_loan          c_overdue_loans%ROWTYPE;
    v_new_penalty   NUMBER;
    v_count         NUMBER := 0;
BEGIN
    OPEN c_overdue_loans;
    
    LOOP
        FETCH c_overdue_loans INTO v_loan;
        EXIT WHEN c_overdue_loans%NOTFOUND;
        
        -- Calculate fresh penalty for this loan
        v_new_penalty := calculate_penalty(v_loan.loan_id);
        
        -- Update loan with new penalty
        UPDATE Loans
        SET penalty_amount = v_new_penalty,
            status = 'overdue'
        WHERE loan_id = v_loan.loan_id;
        
        -- Log the penalty update
        INSERT INTO Audit_Log (action_type, table_name, record_id, action_by, details)
        VALUES (
            'PENALTY_UPDATE',
            'LOANS',
            v_loan.loan_id,
            v_loan.borrower_id,
            'Penalty updated to ' || v_new_penalty || 
            ' for loan ' || v_loan.loan_id
        );
        
        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE('Loan ' || v_loan.loan_id || ' penalty updated to: ' || v_new_penalty);
    END LOOP;
    
    CLOSE c_overdue_loans;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Total loans processed: ' || v_count);

EXCEPTION
    WHEN OTHERS THEN
        CLOSE c_overdue_loans;
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'Error processing overdue loans: ' || SQLERRM);
END;
/