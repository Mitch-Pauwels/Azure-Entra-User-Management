# 🧾 SD-1027 - Bulk User Account Creation from CSV

## 📚 Table of Contents
- [🎯 Goal](#goal)
- [🧪 Scenario](#scenario)
- [🧰 Tools Used](#tools-used)
- [⚙️ Automation (PowerShell)](#automation-powershell)

---

## 🎯 Goal

Automate the process of onboarding multiple new users in Microsoft Entra ID using a structured CSV file and PowerShell.

---

## 🧪 Scenario

HR has provided a list of new hires. Your task is to automate their account creation in Microsoft Entra ID using a CSV file that includes:
- UserPrincipalName
- DisplayName
- JobTitle
- Department
- OfficeLocation
- Initial Password

---

## 🧰 Tools Used

| Tool/Service         | Purpose                                              |
|----------------------|------------------------------------------------------|
| Microsoft Graph SDK  | Automating user creation                             |
| PowerShell           | Executing the script                                 |
| Visual Studio Code   | Script editing and execution                         |
| CSV File             | Holds user details like name, UPN, title, etc.       |

---

## ⚙️ Automation (PowerShell)

Run the following script to bulk-create users from the CSV file:

```powershell
.\scriptsulk-user-onboarding.ps1
```

The script:
- Connects to Microsoft Graph
- Reads user data from `sample-data/bulk-user-onboarding.csv`
- Creates new user accounts with job title, department, and office
- Assigns temporary passwords and sets them to change on first sign-in
- Logs success/failure per user
- Prints a summary

📄 Sample CSV path:
```
sample-data/bulk-user-onboarding.csv
```

📷 *Script Execution Output*  
![Bulk onboarding output](./powershell/bulk-onboarding-example.png)

---