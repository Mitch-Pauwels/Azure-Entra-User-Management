# 🎫 Ticket SD-1024 – Password Reset for Locked-Out User

## 🔍 Issue:
James Robson from Finance is locked out of his Microsoft 365 account. He forgot his password and cannot access self-service reset while working remotely.

## 📋 Requested Actions:
- Reset user's password
- Enable "force password change at next login"
- Send new credentials securely to user

## 🛠️ Resolution Steps:

### PowerShell:
```powershell
Set-AzADUserPassword -UserPrincipalName "j.robson@domainjoined.xyz" `
  -Password "N3wP@ssw0rd!" `
  -ForceChangePasswordNextLogin $true
```

### GUI (Azure Portal):
1. Go to **Microsoft Entra ID > Users**
2. Select **James Robson**
3. Click "Reset password"
4. Deliver new password via secure method (email or phone)

✅ **Status:** Resolved — user regained access and updated credentials.
