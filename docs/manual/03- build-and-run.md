# 03 - Build and Run

TAFRA Studio is a Lazarus 4.8 LCL application.

The authoritative way to work on the application is to open `tafrastudio.lpi`
in Lazarus 4.8, then build, run, and debug from the Lazarus IDE.

## Requirements

- Lazarus 4.8
- Free Pascal Compiler bundled with Lazarus
- Lazarus Component Library
- Windows for the initial target environment

## Build from Lazarus

1. Open Lazarus 4.8.
2. Open `tafrastudio.lpi`.
3. Choose `Run > Build` or `Run > Run`.

## Build from Command Line

The project was verified with:

```powershell
C:\lazarus\lazbuild.exe tafrastudio.lpi
```

Current status:

- Build succeeds.
- Current compiler output contains only unused `Sender` hints from standard
  Lazarus event handlers.
- The Analyzer UI is created at runtime inside the Workspace panel.

## Runtime PHP Note

The application expects the private Studio PHP runtime here:

```text
runtime/php/php.exe
```

If that executable is missing, startup logs a PHP health-check warning and the
desktop application continues running.

This is intentional so the Lazarus shell, scanner, and read-only analyzer can
still be used while the bundled PHP runtime is prepared.
