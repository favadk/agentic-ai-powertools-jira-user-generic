using System.ComponentModel;
using System.Text.Json;
using System.Text.Json.Nodes;
using ModelContextProtocol.Server;

/// <summary>
/// MCP tools for test-management Cloud REST API v2.
/// Credentials are read from environment variables:
///   test-management_CLIENT_ID     – test-management Cloud API client ID
///   test-management_CLIENT_SECRET – test-management Cloud API client secret
/// These are set via the "env" block in mcp.local.json (or mcp.json).
/// </summary>
[McpServerToolType]
public static class test-managementTools
{
    // ─── Auth ─────────────────────────────────────────────────────────────────

    [McpServerTool]
    [Description(
        "Authenticate with test-management Cloud API and return a short-lived Bearer token. " +
        "Reads test-management_CLIENT_ID and test-management_CLIENT_SECRET from environment variables by default. " +
        "You can override them by passing clientId / clientSecret explicitly.")]
    public static async Task<string> test-managementAuthenticate(
        [Description("Override test-management_CLIENT_ID env var (optional).")] string? clientId = null,
        [Description("Override test-management_CLIENT_SECRET env var (optional).")] string? clientSecret = null)
    {
        var id = clientId ?? Env("test-management_CLIENT_ID");
        var secret = clientSecret ?? Env("test-management_CLIENT_SECRET");

        var token = await test-management.Mcp.test-managementClient.GetTokenAsync(id, secret);
        return $"Authenticated successfully. Token length: {token.Length} chars.\nToken: {token}";
    }

    // ─── Import / Steps ──────────────────────────────────────────────────────

    [McpServerTool]
    [Description(
        "Import (or overwrite) test steps for one or more test-management Test issues using the test-management Cloud " +
        "/import/test endpoint. Provide either a file path to a JSON file or a raw JSON string. " +
        "The JSON must be an array of test objects conforming to the test-management Cloud import schema.")]
    public static async Task<string> test-managementImportTestSteps(
        [Description(
            "Bearer token obtained from test-managementAuthenticate. " +
            "If omitted, test-managementAuthenticate is called automatically using env vars.")] string? token,
        [Description(
            "Absolute path to a .json file containing the test-management import payload array. " +
            "Provide this OR jsonPayload, not both.")] string? jsonFilePath = null,
        [Description(
            "Raw JSON string of the test-management import payload array. " +
            "Provide this OR jsonFilePath, not both.")] string? jsonPayload = null)
    {
        var bearerToken = token ?? await GetTokenFromEnv();

        string payload;
        if (!string.IsNullOrWhiteSpace(jsonFilePath))
        {
            if (!File.Exists(jsonFilePath))
                return $"ERROR: File not found: {jsonFilePath}";
            payload = await File.ReadAllTextAsync(jsonFilePath);
        }
        else if (!string.IsNullOrWhiteSpace(jsonPayload))
        {
            payload = jsonPayload;
        }
        else
        {
            return "ERROR: Provide either jsonFilePath or jsonPayload.";
        }

        var result = await test-management.Mcp.test-managementClient.ImportTestStepsAsync(bearerToken, payload);
        return result?.ToJsonString(new JsonSerializerOptions { WriteIndented = true })
               ?? "Import completed (no response body).";
    }

    // ─── Test Runs ────────────────────────────────────────────────────────────

    [McpServerTool]
    [Description(
        "Get details (including step results) for a specific test-management test run by its numeric test-run ID. " +
        "The test-run ID can be found via test-managementGetTestRunsInExecution.")]
    public static async Task<string> test-managementGetTestRun(
        [Description("Bearer token from test-managementAuthenticate (auto-fetched if omitted).")] string? token,
        [Description("Numeric test-management test-run ID (e.g. '12345').")] string testRunId)
    {
        var bearerToken = token ?? await GetTokenFromEnv();
        var result = await test-management.Mcp.test-managementClient.GetTestRunAsync(bearerToken, testRunId);
        return result?.ToJsonString(new JsonSerializerOptions { WriteIndented = true })
               ?? "No data returned.";
    }

    [McpServerTool]
    [Description(
        "List all test runs inside a Test Execution issue. " +
        "Returns a JSON array with testRunId, issueId, status, etc. for each test.")]
    public static async Task<string> test-managementGetTestRunsInExecution(
        [Description("Bearer token from test-managementAuthenticate (auto-fetched if omitted).")] string? token,
        [Description("issue-tracker issue key of the Test Execution (e.g. 'STORY-0000').")] string testExecutionKey)
    {
        var bearerToken = token ?? await GetTokenFromEnv();
        var result = await test-management.Mcp.test-managementClient.GetTestRunsInExecutionAsync(bearerToken, testExecutionKey);
        return result?.ToJsonString(new JsonSerializerOptions { WriteIndented = true })
               ?? "No data returned.";
    }

    [McpServerTool]
    [Description(
        "Update the overall status of a test run. " +
        "Valid statuses: PASS, FAIL, EXECUTING, TODO (case-sensitive).")]
    public static async Task<string> test-managementSetTestRunStatus(
        [Description("Bearer token from test-managementAuthenticate (auto-fetched if omitted).")] string? token,
        [Description("Numeric test-management test-run ID.")] string testRunId,
        [Description("New status: PASS | FAIL | EXECUTING | TODO.")] string status)
    {
        var bearerToken = token ?? await GetTokenFromEnv();
        var result = await test-management.Mcp.test-managementClient.SetTestRunStatusAsync(bearerToken, testRunId, status);
        return string.IsNullOrWhiteSpace(result)
            ? $"Test run {testRunId} status updated to {status}."
            : result;
    }

    // ─── Steps ───────────────────────────────────────────────────────────────

    [McpServerTool]
    [Description("Get all steps (with current results) for a test run.")]
    public static async Task<string> test-managementGetTestRunSteps(
        [Description("Bearer token from test-managementAuthenticate (auto-fetched if omitted).")] string? token,
        [Description("Numeric test-management test-run ID.")] string testRunId)
    {
        var bearerToken = token ?? await GetTokenFromEnv();
        var result = await test-management.Mcp.test-managementClient.GetTestRunStepsAsync(bearerToken, testRunId);
        return result?.ToJsonString(new JsonSerializerOptions { WriteIndented = true })
               ?? "No steps found.";
    }

    [McpServerTool]
    [Description(
        "Set the result (PASS / FAIL / TODO / EXECUTING) of a single step within a test run. " +
        "Use test-managementGetTestRunSteps first to obtain the stepId values.")]
    public static async Task<string> test-managementSetStepResult(
        [Description("Bearer token from test-managementAuthenticate (auto-fetched if omitted).")] string? token,
        [Description("Numeric test-management test-run ID.")] string testRunId,
        [Description("Step ID (from test-managementGetTestRunSteps response).")] string stepId,
        [Description("Step status: PASS | FAIL | TODO | EXECUTING.")] string status,
        [Description("Optional comment to record against this step.")] string? comment = null,
        [Description("Optional actual result text.")] string? actualResult = null)
    {
        var bearerToken = token ?? await GetTokenFromEnv();
        var result = await test-management.Mcp.test-managementClient.SetStepResultAsync(
            bearerToken, testRunId, stepId, status, comment, actualResult);
        return string.IsNullOrWhiteSpace(result)
            ? $"Step {stepId} in run {testRunId} set to {status}."
            : result;
    }

    // ─── Test Executions ─────────────────────────────────────────────────────

    [McpServerTool]
    [Description(
        "Associate one or more test-management Test issue keys with an existing Test Execution issue. " +
        "Useful after creating a Test Execution via the issue-tracker MCP server.")]
    public static async Task<string> test-managementAddTestsToExecution(
        [Description("Bearer token from test-managementAuthenticate (auto-fetched if omitted).")] string? token,
        [Description("issue-tracker issue key of the Test Execution (e.g. 'STORY-0000').")] string testExecutionKey,
        [Description("Comma-separated list of Test issue keys to add (e.g. 'STORY-0000,STORY-0000').")] string testKeys)
    {
        var bearerToken = token ?? await GetTokenFromEnv();
        var keys = testKeys.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

        if (keys.Length == 0)
            return "ERROR: No test keys provided.";

        var result = await test-management.Mcp.test-managementClient.AddTestsToExecutionAsync(bearerToken, testExecutionKey, keys);
        return result?.ToJsonString(new JsonSerializerOptions { WriteIndented = true })
               ?? $"Tests added to {testExecutionKey}.";
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private static string Env(string name)
    {
        var value = Environment.GetEnvironmentVariable(name);
        if (string.IsNullOrWhiteSpace(value))
            throw new InvalidOperationException(
                $"Environment variable '{name}' is not set. " +
                $"Add it to the 'env' block in .vscode/mcp.local.json under the 'test-management' server entry.");
        return value;
    }

    private static async Task<string> GetTokenFromEnv()
    {
        var id = Env("test-management_CLIENT_ID");
        var secret = Env("test-management_CLIENT_SECRET");
        return await test-management.Mcp.test-managementClient.GetTokenAsync(id, secret);
    }
}
