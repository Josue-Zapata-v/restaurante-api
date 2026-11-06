param()
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    docker info --format '{{.ServerVersion}}' *> $null
    if ($LASTEXITCODE -ne 0) { throw 'Inicia Docker Desktop y espera a que el motor este listo.' }

    # La clave solo se guarda en .env (ignorado por Git) y user-secrets.
    if (!(Test-Path -LiteralPath '.env')) {
        $password = [Guid]::NewGuid().ToString('N') + [Guid]::NewGuid().ToString('N')
        [IO.File]::WriteAllText((Join-Path $projectRoot '.env'), "POSTGRES_PASSWORD=$password`n")
    }
    $passwordLine = Get-Content -LiteralPath '.env' | Where-Object { $_ -match '^POSTGRES_PASSWORD=' } | Select-Object -First 1
    if (!$passwordLine) { throw 'Falta POSTGRES_PASSWORD en el archivo local .env.' }
    $password = $passwordLine.Substring('POSTGRES_PASSWORD='.Length)
    if ([string]::IsNullOrWhiteSpace($password)) { throw 'POSTGRES_PASSWORD no puede estar vacio.' }

    docker compose up -d --wait --wait-timeout 120 postgres
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo iniciar PostgreSQL.' }

    $connection = "Host=localhost;Port=5433;Database=restaurante;Username=restaurante;Password=$password;SSL Mode=Disable"
    dotnet user-secrets set 'ConnectionStrings:RestauranteDb' $connection --project RestauranteApi
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo configurar la conexion local.' }

    'SELECT COUNT(*) FROM public."Mesas"; SELECT COUNT(*) FROM public."Reservas";' |
        docker compose exec -T postgres psql -U restaurante -d restaurante -v ON_ERROR_STOP=1
    if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL inicio, pero no se pudo verificar el esquema. Revisa los logs del contenedor.' }
    Write-Host 'PostgreSQL preparado. Ejecuta: dotnet run --project RestauranteApi --launch-profile http'
}
finally {
    Remove-Variable password,connection -ErrorAction SilentlyContinue
    Pop-Location
}
