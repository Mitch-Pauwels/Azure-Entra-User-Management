# 🎫 Ticket SD-1025 – User Offboarding: Disable Account

## 📘 Table of Contents

- [🖱️ GUI (Azure Portal)](#full-process---azure-portal-gui)
- [💻 PowerShell (Step-by-Step)](#full-process---powershell-step-by-step)
- [⚙️ Script Automation](#full-process---powershell-script-automation)
- [✅ Resolution](#resolution)

---

## 📄 Request Summary

IT was notified that **Oliver Smith** has left the organization and must be offboarded immediately.

## 📝 Requested Actions

- Disable the user account in Microsoft Entra ID
- Prevent any further logins or access

---

## Full Process - Azure Portal (GUI)

### 1. Locate User Account
- Go to **Microsoft Entra ID > Users**
- Search for `oliver.smith@domainjoined.xyz` and open the user profile

### 2. Disable Account
- Click **Edit Properties**
- Toggle **Block sign-in** to **Yes**
- Click **Save**

![Open user profile](./gui/open-user-profile.png)  
![Disable account](./gui/block-sign-in.png)

---

## Full Process - PowerShell (Step-by-Step)

### 1. Disable the User Account
```powershell
$user = Get-MgUser -Filter "userPrincipalName eq 'oliver.smith@domainjoined.xyz'"
Update-MgUser -UserId $user.Id -AccountEnabled:$false
