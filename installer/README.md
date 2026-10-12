# TAFRA Studio release packaging

1. Build `tafrastudio.exe` with Lazarus.
2. Ensure `runtime\php` contains the private PHP runtime and `tools\php\vendor`
   was generated from the committed Composer lock file.
3. Compile `tafra-studio.iss` with Inno Setup Compiler. The installer is written
   to `release\`.

The installer includes the Studio PHP runtime, PHP tools, Composer manifest,
lock file, and resolved vendor dependencies. End users do not need PHP or
Composer installed globally.
