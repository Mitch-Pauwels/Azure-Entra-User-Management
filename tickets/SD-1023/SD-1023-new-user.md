# 🎫 Ticket SD-1023 – New User Account Creation

## 📘 Table of Contents

- [🖱️ GUI (Azure Portal)](#full-process---azure-portal-gui)
- [💻 PowerShell (Step-by-Step)](#full-process---powershell-step-by-step)
- [⚙️ Script Automation](#full-process---powershell-script-automation)
- [📨 Welcome Email Template](#welcome-email-template)
- [✅ Resolution](#resolution)

---

## 📄 Request Summary
HR submitted a request to onboard a new employee, **Emily Carter**, who is joining the **Marketing** department.

## 📝 Requested Actions
- Create Microsoft Entra ID user account
- Add user to "Marketing Team" security group
- Send welcome email with login details

---

## Full Process - Azure Portal (GUI)

### 1. Create User
- Navigate to **Microsoft Entra ID > Users > + New User**
- Fill in user details for Emily Carter
- Leave account enabled and set "Force password change at next login"
- Click **Create**

![User creation in portal](./gui/create-user-portal.png)
![User profile confirmation](./gui/emily-carter-created.png)

---

### 2. Create and Assign Group

> ⚠️ _Note: In a real production environment, the "Marketing Team" group would typically already exist as part of a predefined structure. In this lab, the group is created for demonstration and educational purposes._


- Go to **Microsoft Entra ID > Groups > + New Group**
- Create a **Security group** named `Marketing Team`
- Set membership type to **Assigned**
- Add Emily Carter as a member

![Group creation in portal](./gui/create-group-portal.png)
![User added to group via portal](./gui/add-user-to-group-portal.png)

---

## Full Process - PowerShell (Step-by-Step)

### 1. Create User (if applicable via script)
```powershell
New-MgUser -BodyParameter @{
  accountEnabled = $true
  displayName = "Emily Carter"
  mailNickname = "emily.carter"
  userPrincipalName = "emily.carter@domainjoined.xyz"
  passwordProfile = @{
    forceChangePasswordNextSignIn = $true
    password = "P@ssw0rd123!"
  }
}
```
![Create User via PowerShell](./powershell/create-user-via-ps.png)

### 2. Create Group

> ⚠️ _Note: In a real production environment, the "Marketing Team" group would typically already exist as part of a predefined structure. In this lab, the group is created for demonstration and educational purposes._

```powershell
$groupParams = @{
    DisplayName     = "Marketing Team"
    MailEnabled     = $false
    MailNickname    = "marketingteam"
    SecurityEnabled = $true
    GroupTypes      = @()
}

$group = New-MgGroup @groupParams
```

![Group creation in PowerShell](./powershell/create-security-group-ps.png)

### 3. Add to Group
```powershell
$group = Get-MgGroup -Filter "displayName eq 'Marketing Team'"
$userId = (Get-MgUser -Filter "userPrincipalName eq 'emily.carter@domainjoined.xyz'").Id

New-MgGroupMemberByRef -GroupId $group.Id -BodyParameter @{
  "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$userId"
}
```

![User added to group via PowerShell](./powershell/add-user-to-group-ps.png)

---

## Full Process - PowerShell Script Automation

Once tested manually, the onboarding can be performed using automation scripts:

```powershell
.\scripts\create-user.ps1
.\scripts\create-group.ps1
.\scripts\add-user-to-group.ps1
```

Each script is modular and reusable for future onboarding scenarios. This reflects how most enterprise environments automate identity lifecycle tasks using Entra ID.

![Confirmation - Emily in Marketing Team (via GUI + PowerShell)](./powershell/user-in-group-confirmed.png)

---

## 📨 Welcome Email Template

Although email delivery is not automated due to subscription limitations, the following template is used to send credentials to new employees manually from the admin mailbox:

```
Subject: Welcome to DomainJoined!

Hello Emily,

Your Microsoft 365 account has been created. Please find your login details below:

Username: emily.carter@domainjoined.xyz
Temporary password: P@ssw0rd123!

Log in at https://portal.office.com and follow the prompt to change your password.

Welcome aboard!
- IT Support Team
```

---

## ✅ Resolution
Emily Carter has been successfully onboarded with an active user account, assigned to the Marketing Team group, and sent initial credentials.

🗂️ Ticket Closed.
