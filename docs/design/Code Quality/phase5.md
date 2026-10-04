Phase 5 — TAFRA-Aware Clean Code
Objective: Understand framework architecture and conventions.
Use information obtained by the TAFRA Project Analyzer to detect issues such as:
- Business logic incorrectly placed in controllers.
- Direct DB access where a model/service is expected.
- Incorrect module structure.
- Route convention violations.
- Duplicate module logic.
- TAFRA naming violations.
- Incorrect service/model/controller responsibilities.
Architecture:
Generic PHP Analysis
        +
Project Analyzer Knowledge
        +
TAFRA Rules
        ↓
TAFRA-Aware Recommendations
Milestone: Recommendations understand the TAFRA Framework rather than treating it as an arbitrary PHP project.