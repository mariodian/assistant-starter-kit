# Security Standards

## SQL Injection Prevention
- Always use parameterized queries or prepared statements
- Never concatenate user input into SQL queries
- Use ORM query builders when available
- Validate and sanitize all inputs before database operations

## XSS Prevention
- Escape all user-generated content before rendering
- Use templating engines that auto-escape by default
- Implement Content Security Policy (CSP) headers
- Sanitize HTML if rich text input is required

## Secrets Management
- Never commit API keys, passwords, or tokens to version control
- Use environment variables or secret management services
- Rotate secrets regularly
- Audit dependencies for known vulnerabilities

## Authentication & Authorization
- Implement proper session management
- Use strong, adaptive hashing algorithms (bcrypt, scrypt, Argon2)
- Implement rate limiting on authentication endpoints
- Follow principle of least privilege for permissions
- Validate access on every request, not just at the gateway

## Configuration Security
- Disable debug mode in production
- Use secure HTTP headers
- Implement proper CORS policies
- Regularly update dependencies
- Conduct periodic security scans

## Input Validation
- Validate all inputs on the server side (client-side validation is for UX only)
- Use allowlists over blocklists when possible
- Validate file types and sizes for uploads
- Implement proper error handling that doesn't leak sensitive information