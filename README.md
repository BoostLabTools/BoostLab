# BoostLab

BoostLab is a PowerShell and WPF Windows optimization workflow application for professional technician use.

The project is currently in Phase 1. The GUI shell, stage catalog, and foundational modules are placeholders; no optimization actions have been migrated or implemented.

## Run

From Windows PowerShell:

```powershell
powershell.exe -NoProfile -File .\bootstrap.ps1
```

If local execution policy requires a process-scoped bypass:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

The `source-ultimate` directory is retained only as legacy source reference.
