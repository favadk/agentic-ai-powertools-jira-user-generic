. .\scripts\xray-api.ps1
$tok  = Get-XrayCloudToken
$gql  = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }

function Invoke-Gql($query) {
    $body = @{ query = $query } | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $body
}

Write-Output "=== TestRunEvidenceOperationsInput inputFields ==="
$q = '{ __type(name: "TestRunEvidenceOperationsInput") { kind name inputFields { name type { kind name ofType { kind name ofType { kind name } } } } } }'
$r = Invoke-Gql $q
$r.data.__type | ConvertTo-Json -Depth 10

Write-Output ""
Write-Output "=== All INPUT_OBJECT types with Evidence in name ==="
$q2 = '{ __schema { types { name kind } } }'
$r2 = Invoke-Gql $q2
$r2.data.__schema.types | Where-Object { $_.name -match "Evidence" -and $_.kind -eq "INPUT_OBJECT" }
