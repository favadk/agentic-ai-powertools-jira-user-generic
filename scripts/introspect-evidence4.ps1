. .\scripts\xray-api.ps1
$tok  = Get-XrayCloudToken
$gql  = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }

$body = '{"query":"{ __type(name: \"TestRunEvidenceOperationsInput\") { kind name inputFields { name type { kind name ofType { kind name ofType { kind name } } } } } }"}'
$r = Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $body
$r.data.__type | ConvertTo-Json -Depth 10

Write-Output ""
$body2 = '{"query":"{ __schema { types { name kind } } }"}'
$r2 = Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $body2
Write-Output "=== INPUT_OBJECT types ==="
$r2.data.__schema.types | Where-Object { $_.kind -eq "INPUT_OBJECT" -and $_.name -match "evid|attach" } | Select-Object name
