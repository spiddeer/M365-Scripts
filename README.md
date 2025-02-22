# M365-Scripts

A collection of PowerShell scripts for Microsoft 365 administrators. These scripts help manage SharePoint Online, Teams, and other Microsoft 365 services—handling tasks like enabling intelligent versioning, auditing storage, and automating routine admin tasks.

## 📌 Features
- Enable Intelligent Versioning for SharePoint Online to optimize document versioning and reduce storage usage.
- Monitor and audit storage consumption across SharePoint Online sites.
- Automate administrative tasks such as job tracking and reporting.
- Handle throttling (429 errors) efficiently to prevent script failures in large environments.
- Ensure compliance with best practices for Microsoft 365 administration.

## 🚀 Getting Started

### 1️⃣ Clone the Repository
To get a local copy of the scripts:
```powershell
git clone https://github.com/spiddeer/M365-Scripts.git
cd M365-Scripts
```

### 2️⃣ Install Prerequisites
Ensure you have the necessary PowerShell modules installed before running the scripts.

#### SharePoint Online Management Shell
```powershell
Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Force
```

#### Microsoft Teams PowerShell Module (if needed)
```powershell
Install-Module -Name PowerShellGet -Force -AllowClobber
Install-Module -Name MicrosoftTeams -Force
```

#### Exchange Online (if required for any scripts)
```powershell
Install-Module ExchangeOnlineManagement
```

### 3️⃣ Run a Script
Before executing scripts, ensure you have connected to the appropriate Microsoft 365 services.

Example: To enable Intelligent Versioning on SharePoint Online sites:
```powershell
.\Enable-SPO-IntelVer.ps1
```

To check storage savings after a version trimming job:
```powershell
.\CheckCleardStorage.ps1
```

## 📝 Scripts List

| Script Name | Description |
|------------|-------------|
| `Enable-SPO-IntelVer.ps1` | Enables Intelligent Versioning for SharePoint Online sites to optimize storage. |
| `CheckCleardStorage.ps1` | Retrieves and reports the total storage cleared after running version trimming jobs. |

## ❗ Important Notes
- These scripts require **Global Administrator** or **SharePoint Administrator** permissions.
- Always test scripts in a **sandbox environment** before running them in production.
- Ensure you have a **backup** before running any script that modifies data.
- Scripts should be executed in **PowerShell 5.1+** or **PowerShell Core 7+** for best compatibility.

## 🤝 Contributing
Contributions are welcome! Feel free to:
- Open an **issue** for bug reports, feature requests, or documentation improvements.
- Submit a **pull request** if you have script enhancements.
- Share best practices and additional automation ideas.

## 🐝 License
This project is licensed under the [MIT License](LICENSE).

---
💡 **Maintained by:** [spiddeer](https://github.com/spiddeer)