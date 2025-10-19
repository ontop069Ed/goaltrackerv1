# Run: powershell -ExecutionPolicy Bypass -File .\scripts\fix_client_submodule.ps1
Set-Location 'C:\Users\ed\applications\goaltracker'

# 1) Backup working tree if not already backed up
if (-not (Test-Path '..\client-backup')) {
  Write-Host "Creating backup ..\client-backup"
  Copy-Item -Recurse -Force client ..\client-backup
} else {
  Write-Host "Backup already exists at ..\client-backup"
}

# 2) Show current index entry for troubleshooting
git ls-files -s client || Write-Host "ls-files returned non-zero (ok if client was a gitlink)"

# 3) Force-remove the gitlink from the index (works when 'git rm' fails)
git update-index --force-remove client 2>$null || Write-Host "update-index returned non-zero (may already be removed)"

# 4) Remove leftover submodule metadata
if (Test-Path '.git\modules\client') {
  Remove-Item -Recurse -Force '.git\modules\client'
  Write-Host "Removed .git/modules/client"
}

# 5) Remove submodule section from .gitmodules and .git/config if present
if (Test-Path '.gitmodules') {
  git config -f .gitmodules --remove-section "submodule.client" 2>$null
  if ((Get-Content .gitmodules -Raw).Trim().Length -eq 0) {
    Remove-Item .gitmodules -Force
    Write-Host ".gitmodules removed (was empty)"
  } else {
    git add .gitmodules
    Write-Host ".gitmodules updated"
  }
}
git config --remove-section "submodule.client" 2>$null

# 6) Restore working folder from backup if missing
if (-not (Test-Path 'client') -and (Test-Path '..\client-backup')) {
  Move-Item ..\client-backup client
  Write-Host "Restored client from backup"
}

# 7) Force-add and commit the client folder
git add -f client
git add -A

if (git diff --cached --quiet) {
  Write-Host "Nothing staged to commit. Run `git status --porcelain --untracked-files=all` to inspect."
} else {
  git commit -m "Convert client submodule into regular folder"
  git push origin HEAD
  Write-Host "Pushed changes to remote."
}