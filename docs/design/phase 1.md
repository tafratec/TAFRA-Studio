Based on the updated `AGENTS.md` and the decision that **Lazarus 4.8 IDE is the authoritative environment for opening, compiling, running, and debugging TAFRA Studio**, I recommend the following revised Phase 1.

# Phase 1 — Studio Foundation & Project Understanding

**Objective:** Establish a native Lazarus 4.8 TAFRA Studio application capable of opening and understanding existing TAFRA Framework projects. Phase 1 remains primarily **read-only** toward target projects.

### 1.1 Initial Lazarus Project

- Create standard Lazarus **LCL Application**.
- Generate valid `.lpi`, `.lpr`, `.pas`, and `.lfm` files.
- Project must open directly through `tafrastudio.lpi`.
- Compile, run, and debug from **Lazarus 4.8 IDE**.
- Establish `/src`, `/resources`, `/config`, `/docs`, and `/tests`.
- Implement basic application initialization.

**Milestone:** TAFRA Studio opens, compiles, and runs successfully from Lazarus 4.8.

### 1.2 Studio Application Shell

Create the initial desktop interface:

```text
TAFRA Studio
├── Main Menu
├── Toolbar
├── Project Explorer
├── Workspace
├── Output / Log
└── Status Bar
```

Implement basic View, File, Help/About, window resizing, splitters, and panel visibility.

**Milestone:** Stable desktop shell ready to host Studio functionality.

### 1.3 Project Lifecycle

Implement basic project handling:

- Open project directory.
- Close project.
- Maintain current project path.
- Recent projects.
- Display project state in the UI.
- Never modify the opened TAFRA project during this phase.

Introduce a clean service/model boundary rather than keeping project state in form controls.

**Milestone:** Studio can safely open and close TAFRA project directories.

### 1.4 Studio Core Services

Establish only the necessary infrastructure:

- Application configuration.
- Centralized logging.
- Common types/constants.
- Path utilities.
- Error/result handling.
- Basic Studio settings persistence.

Keep the UI thin and independent from these services.

**Milestone:** Core infrastructure exists for subsequent Studio features.

### 1.5 TAFRA Project Detection

Determine whether the selected directory represents a valid or recognizable TAFRA Framework project.

Detection should examine expected elements such as:

```text
/public
/app
/app/bootstrap
/app/config
/app/core
/app/modules
```

Rules must belong to the **framework layer**, not the Main Form.

Return useful detection/validation information rather than simply `True/False`.

**Milestone:** Studio can recognize a TAFRA project and report structural problems.

### 1.6 Internal Project Model

Define the Studio's authoritative in-memory representation:

```text
TTAFRAProject
    │
    └── TTAFRAModule
           │
           └── TTAFRASubmodule
                  ├── Controllers
                  ├── Models
                  ├── Services
                  ├── Views
                  ├── Routes
                  └── Assets
```

The model must remain independent from `TTreeView` and other UI controls.

**Milestone:** TAFRA projects have a clean internal representation usable by future Studio components.

### 1.7 TAFRA Project Scanner

Implement read-only scanning of an existing project.

Detect:

- Modules
- Submodules
- Controllers
- Models
- Services
- Views
- Route files
- Assets
- Relevant configuration files

Populate the internal project model.

Do not attempt full PHP parsing in Phase 1 unless required for a specific structural rule.

**Milestone:** Studio can translate an existing TAFRA directory structure into its internal project model.

### 1.8 Project Explorer

Connect the internal model to the UI:

```text
Project
├── Module A
│   ├── Controllers
│   ├── Models
│   ├── Services
│   ├── Views
│   └── Submodules
└── Module B
```

Support refresh/rescan and basic navigation.

The TreeView remains a **presentation of the model**, never the source of project information.

**Milestone:** Developers can visually inspect a TAFRA project's structure.

### 1.9 Framework Rules & Validation

Centralize TAFRA-specific knowledge:

- Directory conventions.
- Naming conventions.
- Module structure.
- Submodule structure.
- Expected files.
- Required versus optional components.
- Basic structural validation.

Use existing **TAFRA ERP and OTA** projects as reference implementations, while distinguishing framework rules from application-specific conventions.

**Milestone:** Studio can identify basic structural deviations from TAFRA Framework conventions.

### 1.10 Codex Context Foundation

Prepare the architecture for future Codex integration without implementing AI/API integration yet.

Studio should eventually be able to represent/export context such as:

```text
Project
Framework
Modules
Submodules
Relevant Files
Routes
Framework Rules
Requested Operation
```

Maintain the architecture:

```text
TAFRA Project
      ↓
Project Scanner
      ↓
Internal Project Model
      ├──→ Project Explorer
      ├──→ Validator
      └──→ Codex Context Builder
```

**Milestone:** Internal architecture is ready for Phase 2 code-generation/Codex functionality.

---

## Phase 1 Final Milestone

At Phase 1 completion:

> **TAFRA Studio is a valid native Lazarus 4.8 LCL application that can be opened, compiled, run and debugged from Lazarus IDE; safely open an existing TAFRA ERP/OTA project; recognize its TAFRA structure; scan it into an internal project model; display it through Project Explorer; perform basic framework validation; and provide the architectural foundation for Codex-assisted code generation in Phase 2.**

I would **exclude actual module/submodule generation from Phase 1**. Phase 1 teaches the Studio to **understand TAFRA projects first**; Phase 2 can then make it capable of safely **creating and modifying them**.