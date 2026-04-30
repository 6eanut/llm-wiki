# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in LLM Wiki, please report it responsibly.

**Do not open a public issue.** Instead, send a report to [INSERT SECURITY CONTACT].

Please include:

- Description of the vulnerability
- Steps to reproduce
- Affected versions (if known)
- Potential impact

We aim to:

- Acknowledge receipt within 48 hours
- Provide an initial assessment within 5 business days
- Release a fix within 30 days (sooner for critical issues)

## Scope

Security vulnerabilities in the following areas are in scope:

- Shell script injection (command injection, path traversal)
- Unsafe handling of file paths or user input in scripts
- Information disclosure through error messages or logs
- Insecure default configurations

## Out of Scope

- Issues in user-generated wiki content (the skill processes user-provided files)
- Vulnerabilities in dependencies (shellcheck, jq) — report to those projects
- Social engineering attacks

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest  | ✅ |
| Older   | ❌ |

We only support the latest release. Please upgrade before reporting.

## Disclosure Policy

We follow coordinated disclosure:

1. Reporter submits vulnerability privately
2. We confirm and develop a fix
3. We release the fix and publish an advisory
4. Credit is given to the reporter (with permission)
