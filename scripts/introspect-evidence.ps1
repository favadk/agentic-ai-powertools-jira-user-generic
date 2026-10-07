. .\scripts\xray-api.ps1
$tok  = Get-XrayCloudToken
$gql  = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }

function Invoke-Gql($query) {
    $body = @{ query = $query } | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $body
}

# Introspect all Mutation fields
Write-Output "=== Mutation fields ==="
$q = "{ __schema { mutationType { fields { name description args { name type { kind name ofType { kind name } } } } } } }"
$r = Invoke-Gql $q
$r.data.__schema.mutationType.fields | Where-Object { $_.name -match "evidence|attach|upload|run" } | ForEach-Object {
    Write-Output "  Mutation: $($_.name)"
    $_.args | ForEach-Object { Write-Output "    Arg: $($_.name) ($($_.type.kind) $($_.type.name))" }
}

Write-Output ""
Write-Output "=== All mutation names containing 'step' or 'run' ==="
$r.data.__schema.mutationType.fields | Where-Object { $_.name -match "step|run|Test" } | Select-Object -ExpandProperty name
