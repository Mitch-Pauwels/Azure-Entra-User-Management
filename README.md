# 🔷 Azure Entra ID / Microsoft 365 User Management Project 🔷


This project simulates real-world identity, email, and resource management tasks for a fictional managed IT services provider:  
**💼 Company Name:** DomainJoinedGlobal  
**🌐 Domain:** domainjoined.xyz  

All tasks are handled by the internal IT support team and executed using a mix of GUI-based workflows and automation via PowerShell, CLI, and Logic Apps following best practices found in modern cloud environments.

---

## 🎯 Project Goals

- Demonstrate the ability to manage identity lifecycle operations using Microsoft Entra ID
- Provide real-world service desk workflows for Microsoft 365 environments
- Automate repetitive or bulk operations via PowerShell scripts
- Showcase hybrid cloud support scenarios using Azure virtual machines and RBAC
- Simulate professional ticket resolution for onboarding, support, and security tasks

---

## 🛠️ Technologies Covered

- Microsoft Entra ID (Azure Active Directory)
- Microsoft 365 (Exchange Online, Teams, SharePoint, OneDrive)
- PowerShell
- Azure Portal
- Azure CLI
- Logic Apps
- Conditional Access & PIM
- Group-based licensing and access packages

---

## 🗃️ Ticket Overview

### 📁 Identity Lifecycle: Core User Management


| Ticket ID | Title | GUI | Automation |
|-----------|-------|-----|------------|
| [SD-1023](./tickets/SD-1023/SD-1023-new-user.md) | New User Account Creation | ✅ | ✅ |
| [SD-1024](./tickets/SD-1024/SD-1024-password-reset.md) | Password Reset for Locked-Out User | ✅ | ✅ |
| [SD-1025](./tickets/SD-1025/SD-1025-disable-user.md) | User Offboarding: Disable Account | ✅ | ✅ |
| [SD-1026](./tickets/SD-1026/SD-1026-update-user-attributes.md) | Update User Properties (Single Edit) | ✅ | ❌ |
| [SD-1027](./tickets/SD-1027/SD-1027-bulk-user-onboarding.md) | Bulk User Onboarding (via CSV) | ✅ | ✅ |
| [SD-1028](./tickets/SD-1028/SD-1028-bulk-update-user-properties) | Bulk Update User Properties (via CSV) | ❌ | ✅ |

## **🚧 TICKETS BELOW ARE UNDER DEVELOPMENT 🚧**

| Ticket ID | Title | GUI | Automation |
|-----------|-------|-----|------------|
| SD-1029 | Bulk Offboarding (Disable Multiple Users) | ❌ | ✅ |

### 📁 Group & Role Management

| Ticket ID | Title | GUI | Automation |
|-----------|-------|-----|------------|
| SD-1030 | Create Security Groups + Assign Members | ✅ | ✅ |
| SD-1031 | Assign Microsoft 365 Licenses via Group-Based Licensing | ✅ | ✅ |
| SD-1032 | Role Assignment via Azure AD (e.g. Password Administrator) | ✅ | ✅ |
| SD-1033 | Remove User from Group | ✅ | ✅ |

### 📁 Email and Mailbox Management (Exchange Online)

| Ticket ID | Title | GUI | Automation |
|-----------|-------|-----|------------|
| SD-1034 | Create User Mailbox (via license assignment) | ✅ | ✅ |
| SD-1035 | Create Shared Mailbox + Assign Access | ✅ | ✅ |
| SD-1036 | Add Email Alias to User | ✅ | ✅ |
| SD-1037 | Enable Mailbox Auto-Forwarding | ✅ | ✅ |
| SD-1038 | Convert User Mailbox to Shared Mailbox (Offboarding) | ✅ | ✅ |

### 📁 Access Management & Security

| Ticket ID | Title | GUI | Automation |
|-----------|-------|-----|------------|
| SD-1039 | Setup Conditional Access Policy: MFA for Admins | ✅ | ✅ |
| SD-1040 | Configure Self-Service Password Reset (SSPR) | ✅ | ✅ |
| SD-1041 | Create and Assign Access Package (Entitlement Mgmt) | ✅ | ✅ |
| SD-1042 | Set up an Access Review for Group Membership | ✅ | ✅ |
| SD-1043 | Enable PIM for Admin Roles | ✅ | ✅ |

### 📁 Teams, OneDrive, SharePoint Admin Tasks

| Ticket ID | Title | GUI | Automation |
|-----------|-------|-----|------------|
| SD-1044 | Assign Teams License and Verify Access | ✅ | ❌ |
| SD-1045 | Provision SharePoint Site (via M365 Admin Center) | ✅ | ❌ |
| SD-1046 | Verify OneDrive Setup for New User | ✅ | ❌ |

### 📁 Azure Admin / Resource Management

| Ticket ID | Title | GUI | Automation |
|-----------|-------|-----|------------|
| SD-1047 | Create a Windows Server VM with NSG Rules | ✅ | ✅ |
| SD-1048 | Create a Linux VM and SSH using Azure CLI | ❌ | ✅ |
| SD-1049 | Setup an Azure Resource Group + Assign RBAC Role | ✅ | ✅ |
| SD-1050 | Create and Assign Custom RBAC Role | ✅ | ✅ |

### 📁 Automation & Governance

| Ticket ID | Title | GUI | Automation |
|-----------|-------|-----|------------|
| SD-1051 | Create Logic App: Auto-Onboard from Email Trigger | ❌ | ✅ |
| SD-1052 | Schedule User Status Reports via PowerShell (CSV output) | ❌ | ✅ |
| SD-1053 | Automate License Assignment from CSV | ❌ | ✅ |



---
