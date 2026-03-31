# Axios Compromise Test Case

This fixture simulates the March 31, 2026 npm compromise of official `axios` releases.

It includes:
- `axios@1.14.1` as a direct dependency
- `plain-crypto-js@4.2.1` in the lockfile as the malicious transitive dependency

Expected detector result:
- HIGH risk due to compromised package version in `package.json`
- MEDIUM risk due to compromised package versions in `package-lock.json`
