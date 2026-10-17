param(
    [string]$EnvFile = ".env",
    [string]$OutputPath = "fleetpulse.apk",
    [string]$OcrServiceUrl = "https://fleetpulse-ocr.onrender.com"
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$envPath = if ([System.IO.Path]::IsPathRooted($EnvFile)) {
    $EnvFile
} else {
    Join-Path $repoRoot $EnvFile
}

if (-not (Test-Path -LiteralPath $envPath -PathType Leaf)) {
    throw "Environment file not found: $envPath. Copy .env.example to .env and set the Supabase mobile values."
}

$settings = @{}
foreach ($line in Get-Content -LiteralPath $envPath) {
    if ($line -match '^\s*([^#=\s]+)\s*=\s*(.*?)\s*$') {
        $name = $Matches[1]
        $value = $Matches[2].Trim()
        if ($value.Length -ge 2 -and
            (($value.StartsWith('"') -and $value.EndsWith('"')) -or
             ($value.StartsWith("'") -and $value.EndsWith("'")))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        $settings[$name] = $value
    }
}

foreach ($required in @('SUPABASE_URL', 'SUPABASE_ANON_KEY')) {
    if ([string]::IsNullOrWhiteSpace($settings[$required])) {
        throw "$required is missing from $envPath. No APK was built."
    }
}

$supabaseUri = $null
if (-not [Uri]::TryCreate($settings['SUPABASE_URL'], [UriKind]::Absolute, [ref]$supabaseUri) -or
    $supabaseUri.Scheme -ne 'https' -or [string]::IsNullOrWhiteSpace($supabaseUri.Host)) {
    throw 'SUPABASE_URL must be a valid HTTPS Supabase project URL. No APK was built.'
}

$ocrUri = $null
if (-not [Uri]::TryCreate($OcrServiceUrl, [UriKind]::Absolute, [ref]$ocrUri) -or
    $ocrUri.Scheme -ne 'https' -or [string]::IsNullOrWhiteSpace($ocrUri.Host)) {
    throw 'OcrServiceUrl must be an externally reachable HTTPS service URL. No APK was built.'
}
$localOcrHosts = @('localhost', 'host.docker.internal', '10.0.2.2', '0.0.0.0', '::1')
if ($localOcrHosts -contains $ocrUri.Host.ToLowerInvariant() -or
    $ocrUri.Host -match '^127(?:\.\d{1,3}){3}$' -or $ocrUri.Host.EndsWith('.localhost')) {
    throw 'A release APK cannot use a local OCR host. Use the deployed Render URL. No APK was built.'
}

$defines = @(
    "--dart-define=SUPABASE_URL=$($settings['SUPABASE_URL'])",
    "--dart-define=SUPABASE_ANON_KEY=$($settings['SUPABASE_ANON_KEY'])",
    "--dart-define=OCR_SERVICE_URL=$OcrServiceUrl"
)

Push-Location $repoRoot
try {
    & flutter build apk --release --target-platform android-arm64 @defines
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter release build failed with exit code $LASTEXITCODE."
    }

    $apkPath = Join-Path $repoRoot 'build/app/outputs/flutter-apk/app-release.apk'
    if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
        throw "Flutter did not produce the expected APK: $apkPath"
    }

    $sdkRoot = $env:ANDROID_SDK_ROOT
    if ([string]::IsNullOrWhiteSpace($sdkRoot)) { $sdkRoot = $env:ANDROID_HOME }
    if ([string]::IsNullOrWhiteSpace($sdkRoot)) {
        $sdkRoot = Join-Path $env:LOCALAPPDATA 'Android/Sdk'
    }
    $buildTools = Get-ChildItem -LiteralPath (Join-Path $sdkRoot 'build-tools') -Directory |
        Sort-Object { [version]($_.Name -replace '-.*$', '') } -Descending |
        Select-Object -First 1
    if (-not $buildTools) { throw "Android build-tools were not found under $sdkRoot." }
    $apksigner = Join-Path $buildTools.FullName 'apksigner.bat'
    if (-not (Test-Path -LiteralPath $apksigner)) { throw "apksigner was not found at $apksigner." }

    $hasReleaseSigning = Test-Path -LiteralPath (Join-Path $repoRoot 'android/key.properties')
    if ($hasReleaseSigning) {
        & $apksigner verify --verbose $apkPath
        if ($LASTEXITCODE -ne 0) { throw 'The release APK signature could not be verified.' }
    } else {
        $internalKey = Join-Path $repoRoot 'tmp/fleetpulse-debug-signing.jks'
        if (-not (Test-Path -LiteralPath $internalKey)) {
            throw 'No Android release signing configuration exists. Add android/key.properties for production signing or place the internal test signing key at tmp/fleetpulse-debug-signing.jks.'
        }
        $signedPath = Join-Path $repoRoot 'build/app/outputs/flutter-apk/app-release-internal.apk'
        & $apksigner sign --ks $internalKey --ks-key-alias androiddebugkey `
            --ks-pass pass:android --key-pass pass:android --out $signedPath $apkPath
        if ($LASTEXITCODE -ne 0) { throw 'Internal test signing failed.' }
        & $apksigner verify --verbose $signedPath
        if ($LASTEXITCODE -ne 0) { throw 'The internally signed APK signature could not be verified.' }
        $apkPath = $signedPath
        Write-Warning 'No release keystore is configured. This APK is signed with the local internal test key and is not for production distribution.'
    }

    $destination = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
        $OutputPath
    } else {
        Join-Path $repoRoot $OutputPath
    }
    Copy-Item -LiteralPath $apkPath -Destination $destination -Force
    Write-Output "APK created: $destination"
    Write-Output "Size: $((Get-Item -LiteralPath $destination).Length) bytes"
} finally {
    Pop-Location
}
