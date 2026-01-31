# Contributing to WireGuard Endpoint Finder

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Submitting Changes](#submitting-changes)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)

---

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors, regardless of experience level, background, or identity.

### Expected Behavior

- Be respectful and constructive
- Welcome newcomers and help them learn
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or insulting comments
- Personal or political attacks
- Publishing others' private information
- Any conduct inappropriate in a professional setting

---

## Getting Started

### Prerequisites

Before contributing, ensure you have:

1. **Hardware**: MikroTik router with RouterOS 7.20+
2. **Knowledge**: Basic understanding of:
   - RouterOS scripting
   - WireGuard VPN
   - Network routing concepts
3. **Tools**:
   - Git for version control
   - Text editor (VS Code, Sublime, etc.)
   - SSH client for router access
   - WinBox (optional, for GUI access)

### Setting Up Your Development Environment

1. **Fork the Repository**
   ```bash
   # Click "Fork" on GitHub, then clone your fork
   git clone https://github.com/YOUR-USERNAME/mikrotik-warp-finder.git
   cd mikrotik-warp-finder
   ```

2. **Add Upstream Remote**
   ```bash
   git remote add upstream https://github.com/ORIGINAL-OWNER/mikrotik-warp-finder.git
   ```

3. **Create Test Environment**
   - Set up a test MikroTik router (CHR works great)
   - Configure WireGuard interface
   - Don't test on production routers!

---

## How to Contribute

### Ways to Contribute

1. **Code Contributions**
   - Fix bugs
   - Add new features
   - Improve performance
   - Enhance error handling

2. **Documentation**
   - Improve README
   - Add tutorials
   - Fix typos
   - Translate documentation

3. **Testing**
   - Test on different RouterOS versions
   - Test on different hardware
   - Report compatibility issues
   - Validate endpoint lists

4. **Community Support**
   - Answer questions in issues
   - Help troubleshoot problems
   - Share your use cases
   - Provide feedback

---

## Development Setup

### Testing Configuration

Create a test configuration file:

```routeros
# test-config.rsc
# Use this for testing - don't commit credentials!

:local wgInterface "wgcf-test"
:local checkAddress "1.1.1.1"
:global DEBUG 1
```

### Development Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Edit the script
   - Add comments
   - Test thoroughly

3. **Test on RouterOS**
   ```bash
   # Upload to test router
   scp warp-finder-improved.rsc admin@test-router:/
   
   # SSH and import
   ssh admin@test-router
   /import warp-finder-improved.rsc
   ```

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "Add feature: description"
   ```

5. **Push to Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create Pull Request**
   - Go to GitHub
   - Click "New Pull Request"
   - Fill out template
   - Wait for review

---

## Coding Standards

### RouterOS Scripting Guidelines

#### Naming Conventions

```routeros
# Local variables: camelCase
:local myVariable "value"
:local endpointAddress "192.168.1.1"

# Global variables: camelCase with descriptive names
:global ipPrefixes [:toarray "..."]
:global DEBUG 1

# Functions: camelCase
:local myFunction do={
    # function body
}

# Constants: UPPER_CASE (if applicable)
:local MAX_ATTEMPTS 25
```

#### Code Formatting

```routeros
# Use consistent indentation (4 spaces)
:if ($condition) do={
    :local variable "value"
    :if ($nestedCondition) do={
        # nested code
    }
}

# Add spaces around operators
:set result ($value1 + $value2)

# One statement per line
:local var1 "value1"
:local var2 "value2"
```

#### Comments

```routeros
# Section headers - use separator lines
# ============================================================================
# MAJOR SECTION
# ============================================================================

# Subsection headers
# ----------------------------------------------------------------------------
# Subsection Name
# ----------------------------------------------------------------------------

# Inline comments - explain WHY, not WHAT
:local randomValue ($seed * 17 + $attempt)  # Use prime multiplier for better distribution

# Function documentation
# Generate random number using system entropy
# Parameters: $1=multiplier, $2=modulo, $3=offset
# Returns: Random number between 0 and (modulo-1)
:local generateRandom do={
    # implementation
}
```

#### Error Handling

```routeros
# Always validate inputs
:if ([:len $array] = 0) do={
    :log error "Array is empty!"
    :error "Cannot proceed"
}

# Use meaningful error messages
:if ($peerId = "") do={
    :log error "WireGuard peer not found for interface $wgInterface"
    :log error "Check: /interface wireguard peers print"
    :error "Configuration error"
}

# Clean up on errors
:do {
    # risky operation
} on-error={
    # cleanup
    :log error "Operation failed, rolling back"
}
```

### Code Style Checklist

- [ ] Variables use camelCase
- [ ] Functions have descriptive names
- [ ] Comments explain complex logic
- [ ] Error messages are helpful
- [ ] Code follows 4-space indentation
- [ ] No trailing whitespace
- [ ] English language comments only
- [ ] Neutral terminology (avoid blocklist/allowlist, use block/allow)

---

## Testing Guidelines

### Pre-Submission Testing

Before submitting a pull request, test:

1. **Basic Functionality**
   ```routeros
   # Run script with DEBUG=1
   :global DEBUG 1
   /import warp-finder-improved.rsc
   ```

2. **Error Conditions**
   - Invalid interface name
   - Empty arrays
   - Network disconnected
   - WireGuard disabled

3. **Edge Cases**
   - First attempt succeeds
   - All attempts fail
   - Endpoint changes mid-test
   - Router reboot during execution

4. **Multiple RouterOS Versions**
   - Test on 7.20 (minimum)
   - Test on latest stable
   - Test on latest beta (if applicable)

### Test Checklist

- [ ] Script runs without syntax errors
- [ ] Endpoint discovery works
- [ ] Logging output is correct
- [ ] Cleanup happens properly
- [ ] No resource leaks
- [ ] Works on fresh configuration
- [ ] Works after router reboot
- [ ] Compatible with scheduler
- [ ] Compatible with netwatch

### Performance Testing

```routeros
# Measure execution time
:local startTime [/system clock get time]
/import warp-finder-improved.rsc
:local endTime [/system clock get time]
:log info "Execution time: $startTime to $endTime"
```

---

## Submitting Changes

### Pull Request Process

1. **Update Documentation**
   - Update README if needed
   - Add entry to CHANGELOG
   - Update code comments

2. **Self-Review**
   - Read through your changes
   - Check for typos
   - Verify formatting
   - Test one more time

3. **Create Pull Request**
   - Use descriptive title
   - Fill out PR template completely
   - Reference related issues
   - Add screenshots if relevant

4. **Respond to Reviews**
   - Address feedback promptly
   - Make requested changes
   - Ask questions if unclear
   - Be respectful

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Testing Done
- [ ] Tested on RouterOS 7.20
- [ ] Tested on RouterOS 7.x (latest)
- [ ] Tested all error conditions
- [ ] Updated documentation

## Checklist
- [ ] Code follows project style guidelines
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] CHANGELOG updated
- [ ] No breaking changes (or documented)

## Related Issues
Fixes #123
Related to #456
```

### Commit Message Guidelines

```bash
# Format: <type>: <subject>

# Types:
# feat: New feature
# fix: Bug fix
# docs: Documentation changes
# style: Formatting, missing semicolons, etc.
# refactor: Code restructuring
# test: Adding tests
# chore: Maintenance tasks

# Examples:
git commit -m "feat: add IPv6 endpoint support"
git commit -m "fix: correct array initialization error"
git commit -m "docs: update installation instructions"
git commit -m "refactor: improve random number generation"
```

---

## Reporting Bugs

### Before Reporting

1. **Search existing issues** - Your bug may already be reported
2. **Test on latest version** - Bug might be fixed already
3. **Verify it's a script issue** - Not a RouterOS or WireGuard problem
4. **Try to reproduce** - Can you make it happen again?

### Bug Report Template

```markdown
## Bug Description
Clear description of the bug

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Steps to Reproduce
1. Configure WireGuard...
2. Run script with...
3. Observe error...

## Environment
- RouterOS Version: 7.20.1
- Hardware: RB750Gr3
- Script Version: 1.0.0
- WireGuard Config: [paste relevant config]

## Logs
```routeros
# Paste relevant logs here
[paste logs]
```

## Additional Context
Any other relevant information
```

### Providing Logs

```routeros
# Enable debug mode
:global DEBUG 1

# Run script
/import warp-finder-improved.rsc

# Export logs
/log print where topics~"script"

# Or export to file
/log print file=debug-log where topics~"script"
```

---

## Suggesting Features

### Feature Request Template

```markdown
## Feature Description
Clear description of the feature

## Use Case
Why is this feature needed?
Who will benefit?

## Proposed Solution
How should it work?

## Alternatives Considered
What other approaches did you think about?

## Implementation Ideas
```routeros
# Pseudo-code or example
:local newFeature do={
    # implementation concept
}
```

## Additional Context
Screenshots, diagrams, references
```

### Good Feature Requests

✅ **Good**: "Add support for testing multiple endpoints concurrently to speed up discovery"
- Clear and specific
- Explains benefit
- Technically feasible

❌ **Bad**: "Make it faster"
- Vague
- No details
- Unclear benefit

---

## Communication Channels

### GitHub Issues
- Bug reports
- Feature requests
- General questions

### Discussions
- Ideas and brainstorming
- Show and tell
- Q&A

### Pull Requests
- Code contributions
- Documentation improvements

---

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Credited in release notes
- Mentioned in changelog
- Thanked publicly 🎉

---

## Questions?

- Check existing documentation
- Search closed issues
- Ask in discussions
- Contact maintainers

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to make this project better!** 🙌
