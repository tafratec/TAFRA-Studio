The idea is valuable and fits TAFRA Studio very well, especially because the app already has project tree/file selection and a source viewer.

I recommend implementing it later as a “Code Flow Diagram” feature, not as a generic drawing tool.

Recommended user flow:

```text
User selects PHP file
→ TAFRA Studio shows source
→ User selects method/function/class method
→ Generate Flowchart
→ Preview SVG
→ Save As...
→ User chooses output location
```

Best menu/location:

```text
Project
`-- Code Intelligence
    `-- Generate Flowchart from Method...
```

or from right-click:

```text
Project Tree / File Workspace / Source Viewer
`-- Generate Method Flowchart...
```

## Added value

This would help developers quickly understand:

- controller action logic;
- service method flow;
- validation paths;
- conditional branches;
- loops;
- early returns;
- error handling;
- calls to model/service/helper methods.

For legacy or unfamiliar TAFRA projects, this is very useful.

## Recommended scope

Start with PHP methods/functions only.

Phase 1 should support:

- selected PHP file;
- list of detected functions/methods;
- generate flowchart for one selected method;
- output SVG;
- Save As dialog;
- no source code modification.

Do not start with full-project diagrams. That would become too complex and noisy.

## Recommended technical approach

Use PHP tooling, not Pascal parsing.

Reason: PHP AST parsing is better handled by mature PHP packages.

Recommended PHP package:

```text
nikic/php-parser
```

Suggested pipeline:

```text
Lazarus UI
→ TPHPToolRunner
→ PHP flowchart tool
→ nikic/php-parser
→ JSON flow model
→ Pascal SVG renderer or PHP SVG renderer
→ Preview / Save SVG
```

I recommend returning JSON first, then generating SVG from that model. This keeps the architecture clean.

Example internal JSON model:

```json
{
  "success": true,
  "method": "store",
  "nodes": [
    { "id": "start", "type": "start", "label": "Start" },
    { "id": "if1", "type": "decision", "label": "Is valid?" },
    { "id": "return1", "type": "return", "label": "Return error" }
  ],
  "edges": [
    { "from": "start", "to": "if1" },
    { "from": "if1", "to": "return1", "label": "No" }
  ]
}
```

Then generate SVG from the model.

## Recommended SVG style

Use simple readable shapes:

| Logic item | SVG shape |
|---|---|
| Start / End | rounded rectangle |
| Statement | rectangle |
| If / switch | diamond |
| Loop | hexagon or labeled rectangle |
| Return / throw | rounded rectangle |
| Function call | rectangle with call label |

Keep the first version simple and readable, not decorative.

## Important limitations

The first version should not try to fully understand runtime behavior.

Avoid attempting to resolve:

- dynamic method calls;
- framework magic methods;
- runtime dependency injection;
- complex includes;
- database behavior;
- JavaScript/client-side flow.

Instead, display what is statically visible in the selected method.

## Save behavior

Use a normal Save dialog:

```text
Save Flowchart As...
```

Default filename:

```text
ClassName-methodName-flowchart.svg
```

Example:

```text
ItemsController-store-flowchart.svg
```

The user should choose the destination folder.

## My recommendation

Yes, implement this feature, but in phases:

1. Detect methods/functions in selected PHP file.
2. Let user choose one method.
3. Parse method with PHP AST.
4. Generate internal flow model.
5. Render/save SVG.
6. Later add preview tab.
7. Later add call-depth expansion.

Do not build a custom PHP parser in Pascal. Use PHP AST tooling through `TPHPToolRunner`, then let TAFRA Studio orchestrate selection, preview, and saving.