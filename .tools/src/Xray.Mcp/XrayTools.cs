using System.ComponentModel;
using System.Text.Json;
using System.Text.Json.Nodes;
using ModelContextProtocol.Server;

/// <summary>
/// MCP tools for Xray Cloud REST API v2.
/// Credentials are read from environment variables:
///   XRAY_CLIENT_ID     – Xray Cloud API client ID
///   XRAY_CLIENT_SECRET – Xray Cloud API client secret
/// These are set via the "env" block in mcp.local.json (or mcp.json).
/// </summary>
[McpServerToolType]
public static class XrayTools
{
    // ─── Auth ─────────────────────────────────────────────────────────────────

    [McpServerTool]
    [Description(
        "Authenticate with Xray Cloud API and return a short-lived Bearer token. " +
        "Reads XRAY_CLIENT_ID and XRAY_CLIENT_SECRET from environment variables by default. " +
        "You can override them by passing clientId / clientSecret explicitly.")]
    public static async Task<string> XrayAuthenticate(
        [Description("Override XRAY_CLIENT_ID env var (optional).")] string? clientId = null,
        [Description("Override XRAY_CLIENT_SECRET env var (optional).")] string? clientSecret = null)
    {
        var id = clientId ?? Env("XRAY_CLIENT_ID");
        var secret = clientSecret ?? Env("XRAY_CLIENT_SECRET");

        var token = await Xray.Mcp.XrayClient.GetTokenAsync(id, secret);
        return $"Authenticated successfully. Token length: {token.Length} chars.\nToken: {token}";
    }

    // ─── Import / Steps ──────────────────────────────────────────────────────

    [McpServerTool]
    [Description(
        "Import (or overwrite) test steps for one or more Xray Test issues using the Xray Cloud " +
        "/import/test endpoint. Provide either a file path to a JSON file or a raw JSON string. " +
        "The JSON must be an array of test objects conforming to the Xray Cloud import schema.")]
    public static async Task<string> XrayImportTestSteps(
        [Description(
            "Bearer token obtained from XrayAuthenticate. " +
            "If omitted, XrayAuthenticate is called automatically using env vars.")] string? token,
        [Description(
            "Absolute path to a .json file containing the Xray import payload array. " +
            "Provide this OR jsonPayload, not both.")] string? jsonFilePath = null,
        [Description(
            "Raw JSON string of the Xray import payload array. " +
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

        var result = await Xray.Mcp.XrayClient.ImportTestStepsAsync(bearerToken, payload);
        return result?.ToJsonString(new JsonSerializerOptions { WriteIndented = true })
               ?? "Import completed (no response body).";
    }

    // ─── Test Runs ────────────────────────────────────────────────────────────

    [McpServerTool]
    [Description(
        "Get details (including step results) for a specific Xray test run by its numeric test-run ID. " +
        "The test-run ID can be found via XrayGetTestRunsInExecution.")]
    public static async Task<string> XrayGetTestRun(
        [Description("Bearer token from XrayAuthenticate (auto-fetched if omitted).")] string? token,
        [Description("Numeric Xray test-run ID (e.g. '12345').")] string testRunId)
    {
        var bearerToken = token ?? await GetTokenFromEnv();
        var result = await Xray.Mcp.XrayClient.GetTestRunAsync(bearerToken, testRunId);
        return result?.ToJsonString(new JsonSerializerOptions { WriteIndented = true })
               ?? "No data returned.";
    }

    [McpServerTool]
    [Description(
        "List all test runs inside a Test Execution issue. " +
        "Returns a JSON array with testRunId, issueId, status, etc. for each test.")]
    public static async Task<string> XrayGetTestRunsInExecution(
        [Description("Bearer token from XrayAuthenticate (auto-fetched if omitted).")] string? token,
        [Description("Jira issue key of the Test Execution (e.g. 'OLAC-7500').")] string testExecutionKey)
    {
        var bearerToken = token ?? await GetTokenFromEnv();
        var result = await Xray.Mcp.XrayClient.GetTestRunsInExecutionAsync(bearerToken, testExecutionKey);
        return result?.ToJsonString(new JsonSerializerOptions { WriteIndented = true })
               ?? "No data returned.";
    }

    [McpServerTool]
    [Description(
        "Update the overall status of a test run. " +
        "Valid statuses: PASS, FAIL, EXECUTING, TODO (case-sensitive).")]
    public static async Task<string> XraySetTestRunStatus(
        [Description("Bearer token from XrayAuthenticate (auto-fetched if omitted).")] string? token,
        [Description("Numeric Xray test-run ID.")] string testRunId,
        [Description("New status: PASS | FAIL | EXECUTING | TODO.")] string status)
    {
        var bearerToken = token ?? await GetTokenFromEnv();
        var result = await Xray.Mcp.XrayClient.SetTestRunStatusAsync(bearerToken, testRunId, status);
        return string.IsNullOrWhiteSpace(result)
            ? $"Test run {testRunId} status updated to {status}."
            : result;
    }

    // ─── Steps ───────────────────────────────────────────────────────────────

    [McpServerTool]
    [Description("Get all steps (with current results) for a test run.")]
    public static async Task<string> XrayGetTestRunSteps(
        [Description("Bearer token from XrayAuthenticate (auto-fetched if omitted).")] string? token,
        [Description("Numeric Xray test-run ID.")] string testRunId)
    {
        var bearerToken = token ?? await GetTokenFromEnv();
        var result = await Xray.Mcp.XrayClient.GetTestRunStepsAsync(bearerToken, testRunId);
        return result?.ToJsonString(new JsonSerializerOptions { WriteIndented = true })
               ?? "No steps found.";
    }

    [McpServerTool]
    [Description(
        "Set the result (PASS / FAIL / TODO / EXECUTING) of a single step within a test run. " +
        "Use XrayGetTestRunSteps first to obtain the stepId values.")]
    public static async Task<string> XraySetStepResult(
        [Description("Bearer token from XrayAuthenticate (auto-fetched if omitted).")] string? token,
        [Description("Numeric Xray test-run ID.")] string testRunId,
        [Description("Step ID (from XrayGetTestRunSteps response).")] string stepId,
        [Description("Step status: PASS | FAIL | TODO | EXECUTING.")] string status,
        [Description("Optional comment to record against this step.")] string? comment = null,
        [Description("Optional actual result text.")] string? actualResult = null)
    {
        var bearerToken = token ?? await GetTokenFromEnv();
        var result = await Xray.Mcp.XrayClient.SetStepResultAsync(
            bearerToken, testRunId, stepId, status, comment, actualResult);
        return string.IsNullOrWhiteSpace(result)
            ? $"Step {stepId} in run {testRunId} set to {status}."
            : result;
    }

    // ─── Test Executions ─────────────────────────────────────────────────────

    [McpServerTool]
    [Description(
        "Associate one or more Xray Test issue keys with an existing Test Execution issue. " +
        "Useful after creating a Test Execution via the Jira MCP server.")]
    public static async Task<string> XrayAddTestsToExecution(
        [Description("Bearer token from XrayAuthenticate (auto-fetched if omitted).")] string? token,
        [Description("Jira issue key of the Test Execution (e.g. 'OLAC-7500').")] string testExecutionKey,
        [Description("Comma-separated list of Test issue keys to add (e.g. 'OLAC-7496,OLAC-7497').")] string testKeys)
    {
        var bearerToken = token ?? await GetTokenFromEnv();
        var keys = testKeys.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

        if (keys.Length == 0)
            return "ERROR: No test keys provided.";

        var result = await Xray.Mcp.XrayClient.AddTestsToExecutionAsync(bearerToken, testExecutionKey, keys);
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
                $"Add it to the 'env' block in .vscode/mcp.local.json under the 'xray' server entry.");
        return value;
    }

    private static async Task<string> GetTokenFromEnv()
    {
        var id = Env("XRAY_CLIENT_ID");
        var secret = Env("XRAY_CLIENT_SECRET");
        return await Xray.Mcp.XrayClient.GetTokenAsync(id, secret);
    }
}
