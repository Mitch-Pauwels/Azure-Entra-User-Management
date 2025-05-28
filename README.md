# 🚀 Azure Entra ID User Management Project

This project simulates real-world tasks performed by a Service Desk Engineer in an Azure and Microsoft Entra ID (formerly Azure AD) environment. It showcases how to:

- Create, manage, and secure user accounts in **Microsoft Entra ID**
- Combine **PowerShell automation** and **GUI-based workflows**
- Respond to realistic **IT service desk tickets**
- Build a production-style lab replicating common helpdesk responsibilities

🎯 **Goal:** Demonstrate the ability to manage identity lifecycle operations — user onboarding, updates, and offboarding — using Microsoft Entra ID and automation tools.

---

## 📦 What This Project Covers

✅ Microsoft Entra ID (Azure Active Directory)  
✅ User account creation and management  
✅ Group creation and membership assignment  
✅ GUI-based identity administration  
✅ Automation using PowerShell and Microsoft Graph SDK  
✅ Simulated service desk ticket workflows  
✅ Reusable scripting for onboarding scenarios

---

## 📁 Project Structure

Each task is organized as a service desk ticket (e.g., `SD-1023`), with its own folder containing:

- 🖱️ `gui/` — Azure Portal step-by-step screenshots  
- ⚙️ `powershell/` — PowerShell terminal screenshots  
- 📜 `scripts/` — Automation scripts for repeatable tasks  

---

## 🎫 Ticket Scenarios by Category

Each ticket replicates a real-world support request and includes GUI steps and automation when applicable.

---

### 🔄 User Lifecycle Management

| Ticket ID                                              | Title                              | GUI | Automation |
| ------------------------------------------------------ | ---------------------------------- | --- | ---------- |
| [SD-1023](./tickets/SD-1023/SD-1023-new-user.md)       | New User Account Creation          | ✅  | ✅         |
| [SD-1024](./tickets/SD-1024/SD-1024-password-reset.md) | Password Reset for Locked-Out User | ✅  | ✅         |
| [SD-1025](./tickets/SD-1025/SD-1025-disable-user.md)   | User Offboarding: Disable Account  | ✅  | ✅         |
| SD-1026                                                | Update User Properties (Single)    | ✅  | ❌         |
| SD-1027                                                | Bulk Update User Properties        | ❌  | ✅         |

---

### 👥 Group & Role Management

| Ticket ID  | Title                              | GUI | Automation |
| ---------- | ---------------------------------- | --- | ---------- |
| SD-1030    | Assign User to Security Group      |     |            |
| SD-1031    | Create and Manage Security Groups  |     |            |
| SD-1032    | Assign Built-In Role to User       |     |            |

---

### 📧 Email & Identity

| Ticket ID  | Title                              | GUI | Automation |
| ---------- | ---------------------------------- | --- | ---------- |
| SD-1033    | Set/Change Sign-In Alias (UPN)     |     |            |
| SD-1034    | Block Legacy Authentication        |     |            |
| SD-1035    | Enforce MFA for a Group            |     |            |

---

### 🔐 Security & Compliance

| Ticket ID  | Title                                   | GUI | Automation |
| ---------- | --------------------------------------- | --- | ---------- |
| SD-1036    | Enable User Risk Policy                 |     |            |
| SD-1037    | Export Sign-In Logs for Troubleshooting |     |            |

---

### 🤖 Automation

| Ticket ID  | Title                                         | GUI | Automation |
| ---------- | --------------------------------------------- | --- | ---------- |
| SD-1038    | Bulk Import Users from CSV                   | ❌  | ✅         |
| SD-1039    | Schedule Script with Azure Automation Runbook| ✅  | ✅         |

---

### 🧪 Bonus Scenarios

| Ticket ID  | Title                                              | GUI | Automation |
| ---------- | -------------------------------------------------- | --- | ---------- |
| SD-1040    | Send Welcome Email via Logic App                   | ✅  | ✅         |
| SD-1041    | Set Expiration Policy on Guest Users               | ✅  | ✅         |
| SD-1042    | Conditional Access: Block Outside Trusted Locations| ✅  | ✅         |

---
