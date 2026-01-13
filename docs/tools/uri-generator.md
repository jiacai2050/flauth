# TOTP URI Generator

This tool allows you to generate a standard `otpauth://` URI and QR code for your 2FA accounts manually. This is useful if you have a plain secret key and want to import it into Flauth (or other authenticators) via QR code.

!!! warning "Security Note"
    This generator runs entirely in your browser. No data is sent to any server. However, please ensure you are in a safe environment when handling secret keys.

<style>
  .tool-form {
    max-width: 600px;
    margin: 20px 0;
    padding: 20px;
    border: 1px solid var(--md-default-fg-color--lightest);
    border-radius: 4px;
    background: var(--md-code-bg-color);
  }
  .tool-form label {
    display: block;
    margin-bottom: 8px;
    font-weight: bold;
  }
  .tool-form input {
    width: 100%;
    padding: 8px;
    margin-bottom: 16px;
    border: 1px solid #ccc;
    border-radius: 4px;
    background: var(--md-default-bg-color);
    color: var(--md-default-fg-color);
  }
  .tool-result {
    margin-top: 20px;
    text-align: center;
  }
  #qrcode {
    margin: 20px auto;
    display: flex;
    justify-content: center;
  }
  #uri-output {
    word-break: break-all;
    font-family: monospace;
    padding: 10px;
    background: var(--md-default-fg-color--lightest);
    border-radius: 4px;
  }
</style>

<div class="tool-form">
  <label for="issuer">Issuer (Optional)</label>
  <input type="text" id="issuer" placeholder="e.g. GitHub, Google">

  <label for="account">Account Name (Required)</label>
  <input type="text" id="account" placeholder="e.g. user@example.com">

  <label for="secret">Secret Key (Required)</label>
  <input type="text" id="secret" placeholder="Base32 Secret (e.g. JBSWY3DPEHPK3PXP)">

  <div class="tool-result">
    <div id="qrcode"></div>
    <p><strong>Generated URI:</strong></p>
    <div id="uri-output">Fill in the fields above...</div>
  </div>
</div>

!!! info "How to Import into Flauth"
    If you have multiple accounts to add, you can collect these URIs into a plain text file (one per line), save it with a `.flauth` extension, and use the **Local File** import feature in Flauth.

---

### 中文使用说明

1.  在上方输入框填写 **Issuer** (如 GitHub), **Account** (如 user@mail.com) 和 **Secret** (密钥)。
2.  页面会自动生成二维码和 `otpauth://` 链接。
3.  你可以直接用手机扫描二维码，或者：
    *   将生成的链接复制并保存到文本文件中（每行一个链接）。
    *   将该文件命名为 `backup.flauth`。
    *   在 Flauth 的 **Backup & Restore -> Local File** 页面选择该文件进行导入。

<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
<script>
  const issuerInput = document.getElementById('issuer');
  const accountInput = document.getElementById('account');
  const secretInput = document.getElementById('secret');
  const uriOutput = document.getElementById('uri-output');
  const qrContainer = document.getElementById('qrcode');
  
  let qrCodeObj = null;

  function update() {
    const issuer = issuerInput.value.trim();
    const account = accountInput.value.trim();
    const secret = secretInput.value.trim().replace(/\s/g, '').toUpperCase();

    if (!account || !secret) {
      uriOutput.textContent = 'Please enter Account Name and Secret Key.';
      qrContainer.innerHTML = '';
      qrCodeObj = null;
      return;
    }

    let label = account;
    if (issuer) {
      label = encodeURIComponent(issuer) + ':' + encodeURIComponent(account);
    } else {
      label = encodeURIComponent(account);
    }

    let uri = `otpauth://totp/${label}?secret=${secret}`;
    if (issuer) {
      uri += `&issuer=${encodeURIComponent(issuer)}`;
    }

    uriOutput.textContent = uri;

    // Clear previous QR
    qrContainer.innerHTML = '';
    
    // Generate new QR
    try {
      new QRCode(qrContainer, {
        text: uri,
        width: 200,
        height: 200,
        colorDark : "#000000",
        colorLight : "#ffffff",
        correctLevel : QRCode.CorrectLevel.M
      });
    } catch(e) {
      console.error(e);
      uriOutput.textContent += ' (Error generating QR)';
    }
  }

  issuerInput.addEventListener('input', update);
  accountInput.addEventListener('input', update);
  secretInput.addEventListener('input', update);
</script>
