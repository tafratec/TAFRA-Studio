# Phase 2 — TAFRA Project Analyzer

**Objective:** Build the first practical intelligence layer of TAFRA Studio: a read-only analyzer that scans existing TAFRA Framework projects—especially the ERP and OTA codebases—and converts their structure and conventions into a normalized internal project model.

The analyzer should **understand the project before TAFRA Studio starts generating or modifying code**.

## Phase 2 Contents

### 2.1 Project Selection & Validation
Allow the user to select an existing TAFRA project directory.

Validate basic structure such as:

```text
/public
/app
    /bootstrap
    /config
    /core
    /modules
composer.json
```

Detect whether the project appears to be:
- Standard TAFRA Framework
- TAFRA ERP
- TAFRA OTA
- Unknown/partially compatible project

**Milestone:** TAFRA Studio can safely open and recognize a TAFRA project.

---

### 2.2 Project File Scanner
Implement a recursive scanner for relevant files:

```text
*.php
*.js
*.css
*.html
*.json
*.sql
*.md
```

Initially exclude unnecessary directories such as:

```text
/vendor
/node_modules
.git
/storage/logs
/cache
```

Collect file metadata without modifying project files.

**Milestone:** Studio can build an inventory of the codebase.

---

### 2.3 Module & Submodule Discovery
Analyze `/app/modules` and identify:

```text
Module
 ├── Controllers
 ├── Models
 ├── Services
 ├── Views
 ├── Routes
 ├── Assets
 └── Submodules
```

Build a hierarchy such as:

```text
Accounting
 ├── Configuration
 ├── ChartOfAccounts
 ├── Journals
 └── GeneralLedger
```

Do **not** hard-code ERP or OTA module names; infer them from the project structure.

**Milestone:** Studio displays the actual module/submodule tree.

---

### 2.4 Route Analyzer
Parse TAFRA route definitions, especially module `routes.php` files.

Extract where possible:

```text
HTTP Method
URL/Pattern
Route Name
Controller
Controller Method
Middleware
Module
Submodule
```

Example internal representation:

```text
GET /accounting/journals
        ↓
JournalController
        ↓
index()
```

**Milestone:** Studio understands how requests map into application logic.

---

### 2.5 PHP Component Analyzer
Perform lightweight static analysis of PHP files.

Identify:

```text
Namespaces
Classes
Interfaces
Traits
Methods
Properties
Inheritance
Dependencies
use statements
```

Initially avoid building a full PHP parser/compiler. Phase 2 should extract the information required for TAFRA-specific understanding.

**Milestone:** Studio understands the principal PHP components and their relationships.

---

### 2.6 Database Convention Analyzer
Analyze available SQL/DDL scripts and optionally database-related project definitions.

Detect:

- Table names
- Column names
- Primary keys
- Foreign keys
- Indexes
- table/column comments
- naming prefixes
- module-specific naming patterns

For example:

```text
tf_acct_journal_headers
tf_acct_journal_lines
tf_acct_gl_transactions
```

Infer conventions such as:

```text
tf_
 ↓
TAFRA table prefix

acct
 ↓
Accounting domain/module
```

**Milestone:** Studio can describe the database conventions used by the project.

---

### 2.7 TAFRA Pattern Recognition
This is the most important Phase 2 component.

Detect recurring TAFRA implementation patterns from ERP and OTA, for example:

```text
Route
  ↓
Controller
  ↓
Service
  ↓
Model
  ↓
Database
  ↓
View
```

Also identify conventions for:

- Controllers
- Models
- Services
- Views
- configuration
- modules/submodules
- multilingual resources
- middleware
- validation
- AJAX/API endpoints
- database access

The objective is **pattern discovery**, not AI training at this stage.

---

### 2.8 Normalized Project Model
Convert scan results into a common internal representation independent of ERP or OTA.

Conceptually:

```text
TTafraProject
 ├── Metadata
 ├── Modules[]
 │    └── Submodules[]
 ├── Routes[]
 ├── PHPComponents[]
 ├── DatabaseObjects[]
 ├── Assets[]
 └── DetectedPatterns[]
```

This becomes the API boundary between the **Analyzer** and later TAFRA Studio features.

**Milestone:** Other Studio modules do not need to rescan or directly understand arbitrary source files.

---

### 2.9 Analyzer UI
Add a simple Lazarus interface:

```text
Project Analyzer
────────────────────────────────

Project: D:\Projects\TAFRA-ERP

[ Scan Project ]

Modules        Routes       Database
────────────────────────────────────
Accounting
 ├─ Configuration
 ├─ COA
 ├─ Journals
 └─ General Ledger

Files:       842
Modules:      12
Routes:      176
Tables:       94
```

Provide navigation to inspect discovered information, but **no code modification yet**.

---

### 2.10 Analysis Report & Diagnostics
Generate an analysis summary containing:

```text
Project type
Framework structure
Modules/submodules
Routes
Database conventions
Detected framework patterns
Unknown/unrecognized structures
Warnings
```

This will be particularly useful when comparing **ERP vs OTA implementations**.

---

# Phase 2 Boundary

Phase 2 should remain primarily **read-only**:

> **Scan → Parse → Recognize → Normalize → Display**

It should **not yet generate or rewrite application code**.

The key deliverable is:

```text
Existing ERP / OTA Codebase
          │
          ▼
   Project Scanner
          │
          ▼
    TAFRA Analyzer
          │
          ▼
 Pattern Recognition
          │
          ▼
Normalized Project Model
          │
          ▼
   TAFRA Studio UI
```

### Phase 2 completion milestone

**TAFRA Studio can open an existing ERP or OTA project, automatically discover its structure, modules, submodules, routes, PHP components, database conventions, and recurring TAFRA Framework patterns, and expose this information through a normalized internal project model.**

This phase is strategically important because **Phase 3+ code-generation tools should consume the normalized model rather than make assumptions about how a TAFRA project is structured.**