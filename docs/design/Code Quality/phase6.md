Phase 6 — Optimization & Refactoring Workspace
Objective: Handle higher-risk improvements.
Analyze:
- Repeated database queries.
- N+1-like access patterns.
- Inefficient loops.
- Duplicate calculations.
- Excessive object creation.
- Large classes/methods.
- Architectural duplication.
- Potential service extraction.
The UI should support selecting recommendations individually:
☑ Safe formatting
☑ Remove unused imports
☐ Extract duplicated logic
☐ Optimize database queries
☐ Move logic to service

[Preview Selected Changes]

[Apply Approved Changes]
Then run syntax checks, static analysis and available project tests.
Milestone: Complete controlled refactoring workflow.
Recommended sequence
I would keep the phases strictly ordered:
Foundation → Analysis → Safe Cleanup → Rector → TAFRA-aware Refactoring → Optimization
Most importantly, Phases 1–2 must remain completely read-only. Phase 3 is the point where TAFRA Studio earns permission to alter a project, and even then only after preview and explicit approval.
This separation also fits the broader TAFRA Studio architecture well: the existing Project Analyzer becomes an upstream dependency for Phase 5, rather than making the refactoring subsystem responsible for rediscovering TAFRA architecture itself.