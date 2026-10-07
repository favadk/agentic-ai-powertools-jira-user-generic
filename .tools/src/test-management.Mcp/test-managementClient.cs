using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace test-management.Mcp;

/// <summary>
/// HTTP client wrapper for test-management Cloud REST API v2.
/// Auth endpoint: https://test-management.cloud.gettest-management.app/api/v2/authenticate
/// Base URL:      https://us.test-management.cloud.gettest-management.app/api/v2
/// </summary>
internal static class test-managementClient
{
    private const string AuthEndpoint = "https://test-management.cloud.gettest-management.app/api/v2/authenticate";
    private const string BaseUrl = "https://us.test-management.cloud.gettest-management.app/api/v2";

    // ─── Authentication ───────────────────────────────────────────────────────

    /// <summary>Obtain a short-lived Bearer token from test-management Cloud.</summary>
    public static async Task<string> GetTokenAsync(string clientId, string clientSecret)
    {
        using var http = new HttpClient();
        http.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

        var payload = JsonSerializer.Serialize(new { client_id = clientId, client_secret = clientSecret });
        var content = new StringContent(payload, Encoding.UTF8, "application/json");

        var response = await http.PostAsync(AuthEndpoint, content);
        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"test-management auth failed ({response.StatusCode}): {body}");

        // Response is a plain quoted string, e.g. "eyJ..."
        return body.Trim('"');
    }

    // ─── Test Import ──────────────────────────────────────────────────────────

    /// <summary>
    /// Import (or overwrite) test steps for one or more test-management Test issues
    /// using the /import/test endpoint.  The <paramref name="jsonPayload"/>
    /// must be a JSON array conforming to the test-management Cloud import schema.
    /// </summary>
    public static async Task<JsonNode?> ImportTestStepsAsync(string token, string jsonPayload)
    {
        using var http = BuildAuthorized(token);

        var content = new StringContent(jsonPayload, Encoding.UTF8, "application/json");
        var response = await http.PostAsync($"{BaseUrl}/import/test", content);
        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"test-management import failed ({response.StatusCode}): {body}");

        return JsonNode.Parse(body);
    }

    // ─── Test Executions ─────────────────────────────────────────────────────

    /// <summary>
    /// Associate one or more test keys with an existing Test Execution issue
    /// via POST /testexecutions/{key}/test.
    /// </summary>
    public static async Task<JsonNode?> AddTestsToExecutionAsync(
        string token, string testExecutionKey, IEnumerable<string> testKeys)
    {
        using var http = BuildAuthorized(token);

        var payload = JsonSerializer.Serialize(new { add = testKeys.ToArray() });
        var content = new StringContent(payload, Encoding.UTF8, "application/json");
        var response = await http.PostAsync($"{BaseUrl}/testexecutions/{testExecutionKey}/test", content);
        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"AddTests failed ({response.StatusCode}): {body}");

        return JsonNode.Parse(body);
    }

    // ─── Test Runs ────────────────────────────────────────────────────────────

    /// <summary>Get details for a specific test run by its numeric id.</summary>
    public static async Task<JsonNode?> GetTestRunAsync(string token, string testRunId)
    {
        using var http = BuildAuthorized(token);
        var response = await http.GetAsync($"{BaseUrl}/testrun/{testRunId}");
        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"GetTestRun failed ({response.StatusCode}): {body}");

        return JsonNode.Parse(body);
    }

    /// <summary>
    /// Find the test-run id for a specific test within a test execution.
    /// GET /testexecutions/{execKey}/test → array of test-run objects.
    /// </summary>
    public static async Task<JsonNode?> GetTestRunsInExecutionAsync(string token, string testExecutionKey)
    {
        using var http = BuildAuthorized(token);
        var response = await http.GetAsync($"{BaseUrl}/testexecutions/{testExecutionKey}/test");
        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"GetTestRuns failed ({response.StatusCode}): {body}");

        return JsonNode.Parse(body);
    }

    /// <summary>Update the overall status of a test run (PASS / FAIL / EXECUTING / TODO).</summary>
    public static async Task<string> SetTestRunStatusAsync(string token, string testRunId, string status)
    {
        using var http = BuildAuthorized(token);
        var payload = JsonSerializer.Serialize(new { status });
        var content = new StringContent(payload, Encoding.UTF8, "application/json");
        var response = await http.PutAsync($"{BaseUrl}/testrun/{testRunId}/status", content);
        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"SetTestRunStatus failed ({response.StatusCode}): {body}");

        return body;
    }

    // ─── Test Run Steps ───────────────────────────────────────────────────────

    /// <summary>Get all steps for a test run.</summary>
    public static async Task<JsonNode?> GetTestRunStepsAsync(string token, string testRunId)
    {
        using var http = BuildAuthorized(token);
        var response = await http.GetAsync($"{BaseUrl}/testrun/{testRunId}/step");
        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"GetTestRunSteps failed ({response.StatusCode}): {body}");

        return JsonNode.Parse(body);
    }

    /// <summary>Set the result of a single step within a test run.</summary>
    public static async Task<string> SetStepResultAsync(
        string token, string testRunId, string stepId,
        string status, string? comment = null, string? actualResult = null)
    {
        using var http = BuildAuthorized(token);

        var payload = new JsonObject { ["status"] = status };
        if (!string.IsNullOrWhiteSpace(comment)) payload["comment"] = comment;
        if (!string.IsNullOrWhiteSpace(actualResult)) payload["actualResult"] = actualResult;

        var content = new StringContent(payload.ToJsonString(), Encoding.UTF8, "application/json");
        var response = await http.PutAsync($"{BaseUrl}/testrun/{testRunId}/step/{stepId}/status", content);
        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"SetStepResult failed ({response.StatusCode}): {body}");

        return body;
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private static HttpClient BuildAuthorized(string token)
    {
        var http = new HttpClient();
        http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        http.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        return http;
    }
}
