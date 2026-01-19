# Copilot Instructions for ros-scripts

This is a collection of **MikroTik RouterOS scripts** (`.rsc` files) for network automation and security. Each script is a standalone tool with independent configuration, but all follow the same RouterOS scripting patterns.

## Project Architecture

- **Four independent tools**: Each subdirectory contains a complete, self-contained script with its own README
  - `anomalyze/` - Connection anomaly detection (port scans, TLS timeouts)
  - `asn-to-address-list/` - Fetch ASN prefixes from GitHub repo
  - `cloudflare-ddns/` - Dynamic DNS updates for Cloudflare
  - `resolve-address-lists/` - DNS reverse lookup for firewall rules
- **No shared libraries or dependencies** between scripts
- **RouterOS 7.10+ required** (some scripts require 7.20+)
- **MIT License** - appropriate for network admin automation

## Critical RouterOS Script Patterns

### Configuration Pattern

All scripts use a **configuration section at the top** with global variables (`:global`) and local configuration variables. Example from `anomalyze.rsc`:

```routeros
:global cfgEnabled true
:global cfgMonitoredPorts {443; 80; 8443}
:global cfgLogLevel "warning"
```

Users customize behavior by modifying these variables before running the script.

### Error Handling Pattern

Scripts use `:do { } on-error={ }` blocks for safe operations. See `cloudflare-ddns.rsc` for API calls and `asn-to-address-list.rsc` for file operations.

### Logging Pattern

Use conditional `:log` statements with severity levels (debug, info, warning, error). Some scripts support configurable `logLevel` to control verbosity—see `anomalyze.rsc` for the `logMsg` function pattern.

### External Data Fetching

- `asn-to-address-list.rsc` - Uses `/tool fetch` to download prefix lists from GitHub
- `cloudflare-ddns.rsc` - Uses `/tool fetch` for Cloudflare API with JSON payloads
- `resolve-address-lists.rsc` - Uses `:resolve` for DNS lookups

### Array/Collection Handling

RouterOS uses `{element1; element2}` syntax for arrays (semicolon-separated, not comma-separated). See configuration sections in all scripts.

## When Adding New Scripts

1. **Standalone focus** - Don't try to unify code; each script must work independently
2. **Clear configuration section** - Place all user-configurable variables at the top with comments
3. **Comprehensive README** - Document: features, requirements, installation steps, configuration options, examples, troubleshooting
4. **Detailed comments** - RouterOS syntax is unfamiliar to many; explain the "why" not just the "what"
5. **Error messages** - Include `:log` statements for debugging; users need visibility into script execution

## Documentation Structure

Each script's README follows this pattern:

- Feature list (with emojis for scannability)
- Requirements and prerequisites
- Installation steps
- Configuration section
- Usage and examples
- Troubleshooting
- License

Maintain this consistency for user experience.

## Script Behaviors to Preserve

- **Non-destructive operations** - `resolve-address-lists.rsc` only updates empty comments
- **Timeouts and retries** - Scripts handle network delays with `:delay` statements
- **Allowlist/whitelist support** - `anomalyze.rsc` protects trusted IPs from blocking
- **Temporary file cleanup** - `asn-to-address-list.rsc` removes temp files with `:do { /file remove } on-error={}`
