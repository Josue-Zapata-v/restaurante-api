param(
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [string]$OutputPath = 'evidencias/resultados.json'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http
$apiUri = [Uri]$BaseUrl
if (!$apiUri.IsAbsoluteUri -or ($apiUri.Scheme -ne 'https' -and !$apiUri.IsLoopback)) {
    throw 'Usa una URL HTTPS publica o HTTP de localhost para desarrollo.'
}
$BaseUrl = $BaseUrl.TrimEnd('/')
$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromSeconds(150)
$results = New-Object 'System.Collections.Generic.List[object]'
$createdMesas = New-Object 'System.Collections.Generic.List[int]'
$createdReservas = New-Object 'System.Collections.Generic.List[int]'
$startedAt = [DateTime]::UtcNow.ToString('o')
$failure = $null

function Invoke-Case {
    param([string]$Name, [string]$Method, [string]$Path, [int]$Expected, $Body = $null,
        [hashtable]$Headers = @{})
    $url = if ($Path.StartsWith('http')) { $Path } else { "$BaseUrl$Path" }
    $request = New-Object System.Net.Http.HttpRequestMessage
    $request.Method = New-Object System.Net.Http.HttpMethod($Method)
    $request.RequestUri = [Uri]$url
    $requestBody = $null
    if ($null -ne $Body) {
        $requestBody = $Body | ConvertTo-Json -Depth 10 -Compress
        $request.Content = New-Object System.Net.Http.StringContent($requestBody, [Text.Encoding]::UTF8, 'application/json')
    }
    foreach ($header in $Headers.Keys) { [void]$request.Headers.TryAddWithoutValidation($header, $Headers[$header]) }
    $response = $null
    try {
        $response = $client.SendAsync($request).GetAwaiter().GetResult()
        $content = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        $status = [int]$response.StatusCode
        $location = if ($response.Headers.Location) { $response.Headers.Location.ToString() } else { $null }
        $allowOrigin = @($response.Headers | Where-Object { $_.Key -eq 'Access-Control-Allow-Origin' } |
            ForEach-Object { $_.Value }) -join ','
        [void]$results.Add([pscustomobject]@{
            nombre = $Name; metodo = $Method; url = $url; cuerpoEnviado = $requestBody
            esperado = $Expected; recibido = $status; correcto = ($status -eq $Expected)
            location = $location; allowOrigin = $allowOrigin; respuesta = $content
        })
        Write-Host ("{0} {1} [{2}] {3}" -f $Method, $Path, $status, $Name)
        if ($status -ne $Expected) { throw "$Name esperaba $Expected pero recibio $status. $content" }
        $data = $null
        if ($content -and $response.Content.Headers.ContentType.MediaType -like '*json*') {
            $data = ConvertFrom-Json -InputObject $content
        }
        return [pscustomobject]@{ Data = $data; Location = $location; Body = $content; AllowOrigin = $allowOrigin }
    }
    finally {
        if ($null -ne $response) { $response.Dispose() }
        $request.Dispose()
    }
}

try {
    $estado = Invoke-Case 'API y PostgreSQL disponibles' GET '/api/estado' 200
    if ($estado.Data.baseDeDatos -ne 'PostgreSQL') { throw 'La API no esta conectada al proveedor PostgreSQL esperado.' }
    $null = Invoke-Case 'Swagger en el entorno publicado' GET '/swagger/index.html' 200
    $openapi = Invoke-Case 'Documento OpenAPI' GET '/openapi/v1.json' 200
    if (!$openapi.Data.paths.'/api/Mesas' -and !$openapi.Data.paths.'/api/mesas') {
        throw 'El documento OpenAPI no contiene el controlador Mesas.'
    }
    foreach ($server in $openapi.Data.servers) {
        $resolvedServer = New-Object Uri($apiUri, [string]$server.url)
        if ($resolvedServer.Scheme -ne $apiUri.Scheme -or $resolvedServer.Authority -ne $apiUri.Authority) {
            throw 'Swagger debe usar el mismo origen y protocolo que la API; revisa servers en OpenAPI.'
        }
    }
    $mesas = Invoke-Case 'Listar mesas' GET '/api/mesas' 200
    $used = @($mesas.Data | ForEach-Object { $_.numero })
    $available = @(1..200 | Where-Object { $_ -notin $used } | Select-Object -First 2)
    if ($available.Count -lt 2) { throw 'Se necesitan dos numeros de mesa libres para estas pruebas.' }
    $missing = 2147483647
    $tag = [Guid]::NewGuid().ToString('N').Substring(0, 8)
    $mainBody = @{ numero = $available[0]; capacidad = 4; ubicacion = "Prueba $tag" }
    $main = Invoke-Case 'Crear mesa' POST '/api/mesas' 201 $mainBody
    $mesaId = [int]$main.Data.id
    [void]$createdMesas.Add($mesaId)
    if (!$main.Location -or !$main.Location.EndsWith("/api/Mesas/$mesaId", [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Location del POST de mesa no apunta al recurso creado.'
    }
    $null = Invoke-Case 'Consultar Location de mesa' GET $main.Location 200
    $other = Invoke-Case 'Crear segunda mesa' POST '/api/mesas' 201 @{
        numero = $available[1]; capacidad = 2; ubicacion = "Prueba auxiliar $tag"
    }
    $otherId = [int]$other.Data.id
    [void]$createdMesas.Add($otherId)

    $null = Invoke-Case 'POST mesa duplicada' POST '/api/mesas' 409 $mainBody
    $null = Invoke-Case 'Required automatico' POST '/api/mesas' 400 @{ numero = $available[0]; capacidad = 4 }
    $null = Invoke-Case 'Range automatico' POST '/api/mesas' 400 @{ numero = 0; capacidad = 0; ubicacion = 'Prueba' }
    $null = Invoke-Case 'StringLength automatico' POST '/api/mesas' 400 @{
        numero = $available[0]; capacidad = 4; ubicacion = ('x' * 81)
    }
    $null = Invoke-Case 'Id autogenerado' POST '/api/mesas' 400 @{
        id = 1; numero = $available[0]; capacidad = 4; ubicacion = 'Prueba'
    }
    $null = Invoke-Case 'GET mesa inexistente' GET "/api/mesas/$missing" 404
    $null = Invoke-Case 'PUT mesa con Id distinto' PUT "/api/mesas/$mesaId" 400 @{
        id = $otherId; numero = $available[0]; capacidad = 4; ubicacion = 'Prueba'
    }
    $null = Invoke-Case 'PUT mesa inexistente' PUT "/api/mesas/$missing" 404 @{
        id = $missing; numero = $available[0]; capacidad = 4; ubicacion = 'Prueba'
    }
    $null = Invoke-Case 'PUT numero duplicado' PUT "/api/mesas/$mesaId" 409 @{
        id = $mesaId; numero = $available[1]; capacidad = 4; ubicacion = 'Prueba'
    }
    $null = Invoke-Case 'Modificar mesa' PUT "/api/mesas/$mesaId" 204 @{
        id = $mesaId; numero = $available[0]; capacidad = 6; ubicacion = "Prueba modificada $tag"
    }
    $updatedMesa = Invoke-Case 'Comprobar modificacion de mesa' GET "/api/mesas/$mesaId" 200
    if ($updatedMesa.Data.capacidad -ne 6) { throw 'El PUT de mesa no persistio.' }
    $empty = Invoke-Case 'Mesa existente sin reservas' GET "/api/mesas/$mesaId/reservas" 200
    if (@($empty.Data).Count -ne 0) { throw 'La mesa recien creada no deberia tener reservas.' }
    $null = Invoke-Case 'Ruta anidada inexistente' GET "/api/mesas/$missing/reservas" 404

    $reservaBody = @{
        nombreCliente = "Cliente prueba $tag"; telefono = '999123456'; fechaHora = '2030-12-10T13:00:00'
        cantidadPersonas = 4; mesaId = $mesaId; observaciones = 'Prueba automatizada temporal'
    }
    $reserva = Invoke-Case 'Crear reserva solo con FK' POST '/api/reservas' 201 $reservaBody
    $reservaId = [int]$reserva.Data.id
    [void]$createdReservas.Add($reservaId)
    if (!$reserva.Location -or !$reserva.Location.EndsWith("/api/Reservas/$reservaId", [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Location del POST de reserva no apunta al recurso creado.'
    }
    $byId = Invoke-Case 'Consultar reserva por Location con Include' GET $reserva.Location 200
    if ($byId.Data.mesa.id -ne $mesaId) { throw 'La consulta de reserva no incluye la mesa relacionada.' }
    if ($byId.Data.mesa.PSObject.Properties.Name -contains 'reservas') { throw 'La coleccion Reservas debe estar ignorada en JSON.' }
    $null = Invoke-Case 'Listar reservas' GET '/api/reservas' 200
    $filtered = Invoke-Case 'Filtros combinados' GET "/api/reservas?mesaId=$mesaId&desde=2030-12-10&hasta=2030-12-10T23:59:59" 200
    if (@($filtered.Data).Count -ne 1 -or $filtered.Data[0].id -ne $reservaId) { throw 'Los filtros no devolvieron la reserva esperada.' }
    $excluded = Invoke-Case 'Filtros excluyen fuera del rango' GET "/api/reservas?mesaId=$mesaId&desde=2031-01-01" 200
    if (@($excluded.Data).Count -ne 0) { throw 'El filtro de fecha no excluyo la reserva.' }
    $null = Invoke-Case 'Ruta anidada con reservas' GET "/api/mesas/$mesaId/reservas" 200
    $null = Invoke-Case 'Rango de filtros invertido' GET '/api/reservas?desde=2031-01-01&hasta=2030-01-01' 400
    $null = Invoke-Case 'Filtro mal formado' GET '/api/reservas?mesaId=texto' 400
    $invalid = $reservaBody.Clone(); $invalid.mesaId = $missing
    $null = Invoke-Case 'POST FK inexistente' POST '/api/reservas' 400 $invalid
    $invalid = $reservaBody.Clone(); $invalid.nombreCliente = ' '
    $null = Invoke-Case 'POST nombre en blanco' POST '/api/reservas' 400 $invalid
    $invalid = $reservaBody.Clone(); $invalid.Remove('fechaHora')
    $null = Invoke-Case 'POST fecha omitida' POST '/api/reservas' 400 $invalid
    $invalid = $reservaBody.Clone(); $invalid.fechaHora = '2030-12-10T13:00:00Z'
    $null = Invoke-Case 'POST fecha con zona incompatible' POST '/api/reservas' 400 $invalid
    $invalid = $reservaBody.Clone(); $invalid.cantidadPersonas = 7
    $null = Invoke-Case 'POST supera capacidad' POST '/api/reservas' 409 $invalid
    $null = Invoke-Case 'DELETE mesa con dependientes' DELETE "/api/mesas/$mesaId" 409
    $null = Invoke-Case 'PUT capacidad incompatible' PUT "/api/mesas/$mesaId" 409 @{
        id = $mesaId; numero = $available[0]; capacidad = 2; ubicacion = 'Prueba'
    }
    $null = Invoke-Case 'GET reserva inexistente' GET "/api/reservas/$missing" 404
    $invalid = $reservaBody.Clone(); $invalid.id = $missing
    $null = Invoke-Case 'PUT reserva Id distinto' PUT "/api/reservas/$reservaId" 400 $invalid
    $null = Invoke-Case 'PUT reserva inexistente' PUT "/api/reservas/$missing" 404 $invalid
    $invalid = $reservaBody.Clone(); $invalid.id = $reservaId; $invalid.mesaId = $missing
    $null = Invoke-Case 'PUT FK inexistente' PUT "/api/reservas/$reservaId" 400 $invalid
    $invalid = $reservaBody.Clone(); $invalid.id = $reservaId; $invalid.mesaId = $otherId
    $null = Invoke-Case 'PUT supera capacidad' PUT "/api/reservas/$reservaId" 409 $invalid
    $valid = $reservaBody.Clone(); $valid.id = $reservaId; $valid.cantidadPersonas = 5
    $null = Invoke-Case 'Modificar reserva' PUT "/api/reservas/$reservaId" 204 $valid
    $updatedReserva = Invoke-Case 'Comprobar modificacion de reserva' GET "/api/reservas/$reservaId" 200
    if ($updatedReserva.Data.cantidadPersonas -ne 5) { throw 'El PUT de reserva no persistio.' }
    $null = Invoke-Case 'Eliminar reserva' DELETE "/api/reservas/$reservaId" 204
    [void]$createdReservas.Remove($reservaId)
    $null = Invoke-Case 'Reserva eliminada' GET "/api/reservas/$reservaId" 404
    $null = Invoke-Case 'DELETE reserva inexistente' DELETE "/api/reservas/$missing" 404
    $null = Invoke-Case 'Eliminar mesa sin dependientes' DELETE "/api/mesas/$mesaId" 204
    [void]$createdMesas.Remove($mesaId)
    $null = Invoke-Case 'Mesa eliminada' GET "/api/mesas/$mesaId" 404
    $null = Invoke-Case 'DELETE mesa inexistente' DELETE "/api/mesas/$missing" 404
    $null = Invoke-Case 'Eliminar mesa auxiliar' DELETE "/api/mesas/$otherId" 204
    [void]$createdMesas.Remove($otherId)

    $cors = Invoke-Case 'CORS rechaza origen ajeno' OPTIONS '/api/mesas' 204 $null @{
        Origin = 'https://origen-no-autorizado.example'; 'Access-Control-Request-Method' = 'POST'
    }
    if ($cors.AllowOrigin) { throw 'CORS autorizo un origen ajeno.' }
}
catch { $failure = $_.Exception.Message }
finally {
    foreach ($id in $createdReservas.ToArray()) {
        try { $null = Invoke-Case 'Limpieza de reserva temporal' DELETE "/api/reservas/$id" 204 }
        catch { Write-Warning "No se pudo limpiar la reserva $id"; if (!$failure) { $failure = $_.Exception.Message } }
    }
    foreach ($id in $createdMesas.ToArray()) {
        try { $null = Invoke-Case 'Limpieza de mesa temporal' DELETE "/api/mesas/$id" 204 }
        catch { Write-Warning "No se pudo limpiar la mesa $id"; if (!$failure) { $failure = $_.Exception.Message } }
    }
    $client.Dispose()
    $fullPath = [IO.Path]::GetFullPath($OutputPath)
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($fullPath))
    [pscustomobject]@{
        baseUrl = $BaseUrl; entorno = $(if ($apiUri.IsLoopback) { 'LOCAL - no sustituye pruebas en nube' } else { 'URL publica' })
        inicioUtc = $startedAt; finUtc = [DateTime]::UtcNow.ToString('o'); correcto = !$failure
        error = $failure; total = $results.Count; pruebas = $results.ToArray()
    } | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $fullPath -Encoding UTF8
}
if ($failure) { throw $failure }
Write-Host "$($results.Count) solicitudes verificadas. Reporte: $fullPath"
