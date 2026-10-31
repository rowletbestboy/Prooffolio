$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot 'supabase-config.json'
$examplePath = Join-Path $projectRoot 'supabase-config.example.json'

if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Missing local Supabase config. Copy '$examplePath' to '$configPath' and fill in the public client values."
}

$configJson = Get-Content -LiteralPath $configPath -Raw
try {
    $config = ConvertFrom-Json -InputObject $configJson
}
catch {
    throw 'The local Supabase config is not valid JSON. Correct the file and try again.'
}

if ($null -eq $config -or $config -is [array]) {
    throw 'The local Supabase config must be a JSON object.'
}

$allowedProperties = @(
    'SUPABASE_URL',
    'SUPABASE_PUBLISHABLE_KEY',
    'PORTFOLIO_PUBLIC_BASE_URL'
)
$propertyNames = @($config.PSObject.Properties.Name)
$unknownProperties = @($propertyNames | Where-Object { $_ -cnotin $allowedProperties })
if ($unknownProperties.Count -gt 0) {
    throw 'The local Supabase config contains unsupported fields. Only the URL, publishable key, and portfolio public URL are allowed; never add a secret or service-role key.'
}

foreach ($requiredProperty in @('SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY')) {
    if ($propertyNames -cnotcontains $requiredProperty) {
        throw "The local Supabase config must provide $requiredProperty with its exact name."
    }
    $value = $config.$requiredProperty
    if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) {
        throw "The local Supabase config must provide a non-empty string for $requiredProperty."
    }
    if ($value -cne $value.Trim()) {
        throw "$requiredProperty must not contain surrounding whitespace. Correct the local config and rebuild."
    }
}

if (-not $config.SUPABASE_URL.StartsWith('https://', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'SUPABASE_URL must use HTTPS.'
}
if (-not $config.SUPABASE_PUBLISHABLE_KEY.StartsWith('sb_publishable_', [StringComparison]::Ordinal)) {
    throw 'SUPABASE_PUBLISHABLE_KEY must be a Supabase publishable key, not a secret or service-role key.'
}

if ($propertyNames -ccontains 'PORTFOLIO_PUBLIC_BASE_URL' -and
    $config.PORTFOLIO_PUBLIC_BASE_URL -isnot [string]) {
    throw 'PORTFOLIO_PUBLIC_BASE_URL must be a string when provided.'
}
if ($propertyNames -ccontains 'PORTFOLIO_PUBLIC_BASE_URL' -and
    $config.PORTFOLIO_PUBLIC_BASE_URL -cne $config.PORTFOLIO_PUBLIC_BASE_URL.Trim()) {
    throw 'PORTFOLIO_PUBLIC_BASE_URL must not contain surrounding whitespace. Correct the local config and rebuild.'
}

Push-Location $projectRoot
try {
    & flutter build apk --release "--dart-define-from-file=$configPath"
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter release build failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
