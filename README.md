
# LAB Detailed Steps, Results & Explanation

---

# ✅ LAB 01: Indexing Architecture

## Step-by-Step Execution

### Step 1: Baseline (No Index)
1. Enable execution plan in SSMS & performance counters:
   - Click **Include Actual Execution Plan** or press `Ctrl + M`
   - Execute the following lines:
   ```sql
   SET STATISTICS IO ON;
   SET STATISTICS TIME ON;
   ```
2. Execute:
```sql
SELECT * FROM Orders
WHERE CustomerID = 500 AND Status = 'Waiting Approval';
```
3. Observe:
   - Execution Plan: **Table Scan**
   - High I/O + CPU cost
   - Slow execution time

👉 **Why it matters:**
Without indexes, SQL Server must scan all 1M rows → O(n) complexity.

---

### Step 2: Add Non-Clustered Index
```sql
CREATE NONCLUSTERED INDEX idx_orders_status ON Orders(Status);
```

Re-run query.

Observe:
- Still not optimal for this query
- Scan may still occur

👉 **Why:**
Clustered index helps with sorting/range queries, but not filtering by `Status`.

---

### Step 3: Add Composite Index
```sql
CREATE INDEX idx_orders_customer_status ON Orders(CustomerID, Status);
```

Re-run query.

Observe:
- Execution Plan: **Index Seek ✅**
- Drastic reduction in cost

👉 **Why:**
Index directly matches WHERE clause → O(log n) lookup.

---

### Step 4: Add Covering Index
```sql
CREATE INDEX idx_orders_covering 
ON Orders(CustomerID, Status) 
INCLUDE (TotalAmount, OrderDate);
```

Re-run query.

Observe:
- No Key Lookup
- Fastest execution

👉 **Why:**
All required columns exist in index → no additional table access.

---

## ✅ Final Insight
| Stage | Operator | Performance |
|------|---------|------------|
| No Index | Table Scan | Worst |
| Clustered | Partial improvement | Medium |
| Composite | Index Seek | Good |
| Covering | Seek + No Lookup | Best |

---

# ✅ LAB 02: Query Optimization

## Step 1: Add covering index for OrderDate 
This index will be used for the legacy query on step 2
```sql
CREATE NONCLUSTERED INDEX idx_orders_orderdate2 ON Orders (OrderDate) 
INCLUDE (CustomerID)
```


## Step 2: Run Legacy Query
```sql
SELECT CustomerID FROM Orders WHERE YEAR(OrderDate) = 2026;
```

Observe:
- Execution Plan: Table Scan

👉 **Why:**
Function on column makes query **non-sargable**.

---

## Step 3: Refactor Query
```sql
SELECT CustomerID FROM Orders 
WHERE OrderDate >= '2026-01-01' 
AND OrderDate < '2027-01-01';
```

Observe:
- Execution Plan: Index Seek

👉 **Why:**
Removes function → optimizer can use index.

---

## ✅ Result
- Cost reduced ~70%+
- Faster dashboard load time

---

# ✅ LAB 03: SQL Injection

## Step 1: Execute Vulnerable Query
Try input:
```
' OR 1=1 --
```
```sql
EXEC sp_Login_Unsecured @Username = ''' OR 1=1 --', @Password='';
```

Observe:
- Returns all rows

👉 **Why:**
String concatenation allows injection.

Now Extend your attack to retrieve system information.
Try input:
```
' UNION SELECT name, NULL FROM sys.tables --
```
```sql
EXEC sp_Login_Unsecured
    @Username = ''' OR 1=1; SELECT * FROM sys.tables --', 
    @Password='';
```

Observe:
Returns list of table names from sys.tables
Output now includes database metadata instead of user data

👉 **Why:**
The injected UNION allows combining results from another query
sys.tables is a system catalog view containing all table names
Because the query is built via string concatenation, SQL Server executes both the original query and the injected one

💡 **Learning Point:**
SQL Injection is not just for bypassing login — it can also be used to enumerate database structure (tables, columns, metadata), which is often the first step in a real attack.

---

## Step 2: Use Stored Procedure with Parameterized Query
```sql
EXEC sp_Login @Username = ''' OR 1=1 --', @Password='';
```

Try injection again.

Observe:
- Injection fails ✅

👉 **Why:**
Parameterized queries separate code from data.

---

# ✅ LAB 04: Backup Strategy

## Step 1: Full Backup
```sql
BACKUP DATABASE LabDB TO DISK = 'C:\Backup\LabDB_full.bak';
```

## Step 2: Simulate Activity
Run multiple inserts.

## Step 3: Differential Backup
```sql
BACKUP DATABASE LabDB TO DISK = 'C:\Backup\LabDB_diff.bak' WITH DIFFERENTIAL;
```

---

## ✅ Why This Matters
- Full backup = complete restore point
- Differential = faster daily recovery
- Minimizes production I/O load

---

# ✅ FINAL TAKEAWAYS
- Indexes drastically reduce query cost
- Sargability is critical for performance
- Parameterization prevents security breaches
- Backup strategy ensures business continuity
