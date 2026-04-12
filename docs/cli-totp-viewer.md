# CLI TOTP Viewer

Read a Flauth backup file and print current TOTP codes in the terminal.

## Build

```bash
make build-cli
```

Output:

```bash
build/flauth-cli
```

## Environment variables

- `FLAUTH_BACKUP_FILE`: required, path to the `.flauth` backup file
- `FLAUTH_BACKUP_PASSWORD`: required only for encrypted backups

## Usage

Show all accounts:

```bash
FLAUTH_BACKUP_FILE=./backup.flauth ./build/flauth-cli
```

Show accounts matching a filter:

```bash
FLAUTH_BACKUP_FILE=./backup.flauth ./build/flauth-cli github
```

Show accounts from an encrypted backup:

```bash
FLAUTH_BACKUP_FILE=./backup.flauth \
FLAUTH_BACKUP_PASSWORD='your-password' \
./build/flauth-cli
```

The optional positional argument is a case-insensitive `contains` filter on `issuer` and `name`.

## Output

```text
GitHub  alice@example.com  123456
Google  bob@gmail.com      654321
```

Codes are printed without spaces for easier copying.

## Common errors

- `Backup file is required via FLAUTH_BACKUP_FILE.`
- `Encrypted backup requires FLAUTH_BACKUP_PASSWORD.`
- `Backup file does not exist`
- `No valid accounts found in backup file.`

## Notes

- Supports plain-text and encrypted Flauth backups
- Only reads backup files; does not modify them
- Filter only checks `issuer` and `name`
