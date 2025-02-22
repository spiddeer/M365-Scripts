# M365-Scripts

A collection of PowerShell scripts for Microsoft 365 administrators. These scripts help manage SharePoint Online, Teams, and other Microsoft 365 services—handling tasks like enabling intelligent versioning, auditing storage, and automating routine admin tasks.

## 📌 Features
- Enable Intelligent Versioning for SharePoint Online.
- Audit and retrieve storage information for sites.
- Automate administrative tasks across Microsoft 365.
- Handle throttling (429 errors) efficiently in large environments.

## 🚀 Getting Started

### 1️⃣ Clone the Repository
To get a local copy of the scripts:
```powershell
git clone https://github.com/spiddeer/M365-Scripts.git
cd M365-Scripts
```

### 2️⃣ Install Prerequisites
Ensure you have the necessary PowerShell modules installed:

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
Open PowerShell, navigate to the repository folder, and execute a script:
```powershell
.\Enable-IntelVersioning.ps1
```
Make sure you have connected to your Microsoft 365 services before running the scripts.

## 📝 Scripts List

| Script Name | Description |
|------------|-------------|
| `Enable-IntelVersioning.ps1` | Enables Intelligent Versioning for SharePoint Online sites. |
| `Check-TrimJobProgress.ps1` | Checks the status of ongoing SharePoint file version deletion jobs. |
| `Get-SPOStorageReport.ps1` | Retrieves storage usage details for all SharePoint sites. |

## ❗ Important Notes
- These scripts require **Global Administrator** or **SharePoint Administrator** permissions.
- Always test scripts in a **sandbox environment** before running them in production.
- Ensure you have a **backup** before running any script that modifies data.

## 🤝 Contributing
Contributions are welcome! Feel free to:
- Open an **issue** for bug reports or feature requests.
- Submit a **pull request** if you have script improvements.

## 🐝 License
This project is licensed under the [MIT License](LICENSE).

---
💡 **Maintained by:** [spiddeer](https://github.com/spiddeer)