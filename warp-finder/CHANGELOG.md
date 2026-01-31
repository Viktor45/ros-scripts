# Changelog

All notable changes to the WireGuard Endpoint Finder script will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- IPv6 endpoint support
- Automatic endpoint list updates from Cloudflare
- Backup endpoint failover mechanism

## [1.0.0] - 2025-02-01

### Added
- Initial release of WireGuard Endpoint Finder
- Automatic endpoint discovery from Cloudflare WARP IP ranges
- Random IP and port generation using system entropy
- ICMP ping-based connectivity testing
- Comprehensive debug logging system
- Temporary route creation and cleanup
- WireGuard peer configuration automation
- Error handling and validation
- Professional code structure with sections
- Detailed inline documentation
- Support for RouterOS 7.20+

### Features
- 15 Cloudflare IP prefixes pre-configured
- 52 known working UDP ports
- Configurable maximum attempts (default: 25)
- Configurable ping count (default: 2)
- Adjustable delay between tests (default: 2s)
- Debug mode toggle
- Safe failure handling
- Automatic rollback on errors

### Documentation
- Comprehensive README.md
- Installation instructions
- Configuration guide
- Troubleshooting section
- Usage examples
- Advanced configuration options

### Code Quality
- Follow RouterOS scripting best practices
- Extensive inline comments in English
- Modular function design
- Proper error handling
- Clean code structure
- Neutral terminology (allow/block instead of whitelist/blacklist)

## [0.9.0] - 2025-01-28 (Beta)

### Added
- Beta testing release
- Core endpoint discovery functionality
- Basic ping testing
- Initial IP and port lists

### Changed
- Improved random number generation
- Enhanced logging output

### Fixed
- Route cleanup issues
- Array initialization problems
- Peer configuration timing

## [0.5.0] - 2025-01-20 (Alpha)

### Added
- Alpha release for internal testing
- Proof of concept implementation
- Basic WireGuard peer configuration
- Simple endpoint testing

### Known Issues
- Inconsistent random generation
- Limited error handling
- Verbose logging output
- Manual route cleanup required

---

## Version Numbering

This project follows Semantic Versioning:
- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality in a backwards compatible manner
- **PATCH** version for backwards compatible bug fixes

## Release Types

- **Alpha**: Early testing, not feature complete, may have bugs
- **Beta**: Feature complete, undergoing testing and refinement
- **Release Candidate (RC)**: Nearly ready for production, final testing
- **Stable**: Production-ready release

## How to Upgrade

### From 0.x to 1.0.0
1. Backup your current configuration
2. Download the new script version
3. Review new configuration options
4. Update interface name if changed
5. Import the new script
6. Test in non-production environment first

---

## Support

For questions about specific versions or upgrade paths:
- Open an issue on GitHub
- Check the documentation
- Consult the troubleshooting guide

[unreleased]: https://github.com/viktor45/ros-scripts/warp-finder/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/viktor45/ros-scripts/warp-finder/releases/tag/v1.0.0
[0.9.0]: https://github.com/viktor45/ros-scripts/warp-finder/releases/tag/v0.9.0
[0.5.0]: https://github.com/viktor45/ros-scripts/warp-finder/releases/tag/v0.5.0
