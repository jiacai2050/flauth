# Importing from Aegis Authenticator

Aegis is a popular open-source 2FA manager for Android. Migrating your accounts from Aegis to Flauth is simple and efficient.

## Recommended Method: URI List Import

This method allows you to migrate all accounts at once using Flauth's local import feature.

### Step 1: Export from Aegis
1.  Open **Aegis** on your Android device.
2.  Tap the **Settings** (gear icon) or the three-dot menu.
3.  Go to **Import / Export**.
4.  Select **Export**.
5.  Choose **Plain-text JSON** or **Plain-text URI list**. 
    *   *Note: Flauth prefers the URI list for direct compatibility.*
6.  Tap **Export to file** and save it to your device.

### Step 2: Prepare the file
Flauth recognizes files with the `.flauth` extension. 
1.  Locate the file you just exported (usually named `aegis-export-....txt` or `.json`).
2.  Rename the file extension to `.flauth`. For example: `backup.flauth`.

### Step 3: Import into Flauth
1.  Open **Flauth**.
2.  Go to **Backup & Restore** from the home screen menu.
3.  Switch to the **Local File** tab.
4.  Tap **Import from File**.
5.  Select your `.flauth` file.
6.  Flauth will display a message confirming how many new accounts were imported.

---

## Alternative Method: QR Code (One-by-one)

If you only have a few accounts, you can scan them individually:
1.  In Aegis, long-press an account and select **Show QR code**.
2.  In Flauth, tap the **[+]** button on the home screen.
3.  Select **Scan QR Code** and scan the screen.

## ⚠️ Security Note
After a successful import, please **immediately and securely delete** the plain-text export file from Aegis, as it contains your unencrypted 2FA secrets.
