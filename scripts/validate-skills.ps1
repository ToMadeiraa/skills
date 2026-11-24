# Validate DSH skills: frontmatter, names, relative links.
# Run: powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-skills.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$errors = New-Object System.Collections.ArrayList
$names = @{}
$files = @(Get-ChildItem -Path (Join-Path $root 'skills') -Recurse -Filter 'SKILL.md' -File)
$kebab = '^[a-z0-9]+(-[a-z0-9]+)*$'
$linkPattern = '\]\((?!https?://|mailto:|#)([^)\s]+)\)'
$fileExt = '\.(md|ps1|sh|py|json|ya?ml)$'

foreach ($file in $files) {
    $rel = $file.FullName.Substring($root.Length + 1)
    $raw = [System.IO.File]::ReadAllText($file.FullName)
    $m = [regex]::Match($raw, '(?s)\A---\r?\n(.*?)\r?\n---\r?\n')
    if (-not $m.Success) {
        [void]$errors.Add("${rel}: missing YAML frontmatter")
        continue
    }
    $fm = $m.Groups[1].Value
    $name = ([regex]::Match($fm, '(?m)^name:\s*"?(.+?)"?\s*$')).Groups[1].Value.Trim()
    $desc = ([regex]::Match($fm, '(?m)^description:\s*(\S.*)$')).Groups[1].Value.Trim()

    if (-not $name) {
        [void]$errors.Add("${rel}: missing name")
    } elseif ($name -notmatch $kebab) {
        [void]$errors.Add("${rel}: name '$name' is not kebab-case")
    } elseif ($names.ContainsKey($name)) {
        [void]$errors.Add("${rel}: duplicate name '$name' (also $($names[$name]))")
    } else {
        $names[$name] = $rel
    }

    if (-not $desc) {
        [void]$errors.Add("${rel}: missing description")
    }

    # Relative file links only; skip URLs, anchors, and code-like parentheses.
    $links = [regex]::Matches($raw, $linkPattern)
    foreach ($link in $links) {
        $target = $link.Groups[1].Value
        if ($target -notmatch $fileExt) { continue }
        $path = Join-Path $file.DirectoryName $target
        if (-not (Test-Path -LiteralPath $path)) {
            [void]$errors.Add("${rel}: broken link '$target'")
        }
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Host "FAIL $_" }
    Write-Host "Checked $($files.Count) skill files; errors: $($errors.Count)"
    exit 1
}

Write-Host "OK: $($files.Count) SKILL.md files; frontmatter, names, and links are valid."
exit 0
