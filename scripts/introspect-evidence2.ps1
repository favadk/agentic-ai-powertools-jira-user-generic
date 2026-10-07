. .\scripts\xray-api.ps1
$tok  = Get-XrayCloudToken
$gql  = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }

function Invoke-Gql($query) {
    $body = @{ query = $query } | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $body
}

# Find the EvidenceInput type shape
Write-Output "=== addEvidenceToTestRunStep full arg types ==="
$q = '{ __type(name: "addEvidenceToTestRunStepInput") { fields { name type { kind name ofType { kind name ofType { kind name } } } } } }'
$r = Invoke-Gql $q
$r.data.__type | ConvertTo-Json -Depth 10

Write-Output ""
Write-Output "=== Searching for EvidenceInput types ==="
$q2 = '{ __schema { types { name kind fields { name type { kind name ofType { kind name } } } } } }'
$r2 = Invoke-Gql $q2
$r2.data.__schema.types | Where-Object { $_.name -match "Evidence" } | ForEach-Object {
    Write-Output "Type: $($_.name) ($($_.kind))"
    $_.fields | ForEach-Object { Write-Output "  Field: $($_.name) -> $($_.type.kind) $($_.type.name) $($_.type.ofType.name)" }
}
