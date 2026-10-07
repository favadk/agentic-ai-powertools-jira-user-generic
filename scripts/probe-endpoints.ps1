. .\scripts\test-management-api.ps1
$tok = Get-test-managementCloudToken

Add-Type -AssemblyName System.Net.Http

$runId = "6a5ff87b72d5b592fbee751e"
$step4 = "2cb9dfec-5f85-4d8c-aaa7-fb885b7a7c78"
$fp    = "C:\Agentic-AI\agentic-ai-powertools-issue-tracker-user-generic\docs\TestExecution\evidence\STORY-0000-Cycle1\evidence-step4-01-cognito-signin.png"

$endpoints = @(
    "https://us.test-management.cloud.gettest-management.app/api/v2/testrun/$runId/evidence",
    "https://us.test-management.cloud.gettest-management.app/api/v2/testrun/$runId/step/$step4/evidence",
    "https://test-management.cloud.gettest-management.app/api/v2/testrun/$runId/step/$step4/attachment",
    "https://us.test-management.cloud.gettest-management.app/api/v1/testrun/$runId/step/$step4/attachment"
)

foreach ($url in $endpoints) {
    Write-Output "Trying: $url"
    try {
        $client  = [System.Net.Http.HttpClient]::new()
        $client.DefaultRequestHeaders.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new("Bearer", $tok)
        $content  = [System.Net.Http.MultipartFormDataContent]::new()
        $stream   = [System.IO.File]::OpenRead($fp)
        $filePart = [System.Net.Http.StreamContent]::new($stream)
        $filePart.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::new("image/png")
        $content.Add($filePart, "file", "test.png")
        $response = $client.PostAsync($url, $content).GetAwaiter().GetResult()
        $respBody = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        $stream.Dispose(); $client.Dispose()
        $snippet = $respBody.Substring(0,[Math]::Min(300,$respBody.Length))
        Write-Output "  STATUS $([int]$response.StatusCode): $snippet"
    } catch {
        Write-Output "  EXCEPTION: $($_.Exception.Message)"
    }
}
