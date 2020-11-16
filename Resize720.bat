@echo off

for %%f in (%*) do (
  echo "%%f"
  powershell -NoProfile -ExecutionPolicy Unrestricted ".\resize.ps1" -longside 720 -overwrite y -filename \"%%f\"
)
PAUSE
