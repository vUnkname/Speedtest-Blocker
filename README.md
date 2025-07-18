# 🚀 Speedtest Blocker

<div align="right" dir="rtl">

> **فارسی**: برای مستندات فارسی، لطفاً به این [فایل](https://github.com/vUnkname/Speedtest-Blocker/blob/main/README-FA.md) مراجعه کنید.

</div>

<div align="center">

![Terminal Screenshot](https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/screenshot.png)

</div>

## 📞 Support

- **Telegram Channel**: [@NiGmaServices](https://t.me/NiGmaServices)
- **Sponsor**: [@CloudCubeServer](https://t.me/CloudCubeServer)

## 📝 Introduction
**Speedtest Blocker** is a powerful script for blocking internet speed test websites with support for <b>iptables</b> and <b>nftables</b>.

## 📜 Description
Powerful script for blocking internet speed test websites with support for <b>iptables</b> and <b>nftables</b>

## ✨ Features

- 🔒 **Automatic blocking** of speed test websites (121+ sites)
- 🔓 **One-click unblocking**
- 🔧 **Automatic firewall detection** (<b>iptables</b>/<b>nftables</b>)
- 📊 **Server information display** (Country, IP, ISP)
- 🔄 **SystemD service** for automatic startup
- 📱 **Easy installation** with one command
- 🆕 **Automatic updates** from repository
- ⏰ **Daily checks** for CSV file updates
- 🛡️ **CSV file validation** for security
- 🧹 **Complete system cleanup**

## 🚀 Quick Installation

### Prerequisites Check
```bash
# Check sudo access
sudo -v

# Check for curl or wget
command -v curl || command -v wget

# Check system compatibility
uname -m  # Should display x86_64
```

### Method 1: Direct Installation from Internet
```bash
bash <(curl -Ls https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/ST-Blocker.sh)
```

### Method 2: Download and Run
```bash
wget https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/ST-Blocker.sh
chmod +x ST-Blocker.sh
sudo ./ST-Blocker.sh
```

### Method 3: Manual Dependencies Installation First
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y curl dnsutils <b>iptables</b>

# CentOS/RHEL/Rocky/Alma
sudo yum install -y curl bind-utils <b>iptables</b>

# Then run the script
bash <(curl -Ls https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/ST-Blocker.sh)
```

## 📋 Prerequisites

### System Requirements
- **Operating System**: Ubuntu, Debian, CentOS, AlmaLinux, Rocky Linux
- **Access**: Root access (sudo)
- **Architecture**: x86_64 (64-bit)

### Required Tools (Auto-installed)
- **curl** or **wget** - For downloading files and API requests
- **dig** (dnsutils/bind-utils) - For domain name to IP conversion
- **<b>iptables</b>** or **<b>nftables</b>** - Firewall management
- **systemctl** - SystemD service management
- **jq** (optional) - JSON parsing (uses grep/cut if not available)

### System Commands Used
- `hostname` - Get server IP
- `awk`, `grep`, `cut` - Text processing
- `stat` - File information
- `date` - Time operations

## 🎯 Usage

1. **Run the script**:
   ```bash
   sudo ST-Blocker.sh
   ```

2. **Select option**:
   - `1` - Block speed test websites
   - `2` - Unblock websites
   - `3` - Update website list
   - `4` - Complete cleanup
   - `0` - Exit

## 🔄 Automatic Updates

### ✅ **Automatic Check on Run:**
- The script checks the CSV file every time it runs
- If the CSV file is older than 24 hours, it updates it
- Downloads the latest speed test website list from repository

### 🔧 **Manual Update:**
```bash
# Run script and select option 3
sudo ST-Blocker.sh

# Or direct CSV file update
sudo curl -o /usr/local/bin/speedtest_websites.csv https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/speedtest_websites.csv
```

### 🚫 **Disable Automatic Check:**
```bash
# Run without update check (version 1.0.0)
sudo ST-Blocker.sh --no-update
```

**Note**: The `--no-update` parameter prevents automatic CSV file checking and downloading, going directly to the main menu.

## 📁 Installed Files

- **Main script**: `/usr/local/bin/ST-Blocker.sh`
- **Website list**: `/usr/local/bin/speedtest_websites.csv` (121 sites)
- **SystemD service**: `/etc/systemd/system/speedtest-blocker.service`
- **<b>iptables</b> rules**: `/etc/<b>iptables</b>/rules.v4` (when used)

## 🔧 Service Management

```bash
# Check service status
sudo systemctl status speedtest-blocker

# Stop service
sudo systemctl stop speedtest-blocker

# Restart
sudo systemctl restart speedtest-blocker

# Disable
sudo systemctl disable speedtest-blocker
```

## 🧹 Complete Cleanup

The script includes a complete cleanup option that removes:
- All <b>iptables</b> and <b>nftables</b> rules
- SystemD service and files
- Installed script and CSV files
- Any remaining blocking rules

```bash
# Run script and select option 4
sudo ST-Blocker.sh
```

## 🛡️ Security

- All operations are performed with root access
- Firewall rules are applied safely
- Complete settings restoration capability

## 🔍 Troubleshooting

### Common Issues:

1. **Access Error**:
   ```bash
   sudo chmod +x /usr/local/bin/ST-Blocker.sh
   ```

2. **Missing Dependencies**:
   ```bash
   # Ubuntu/Debian
   sudo apt update && sudo apt install -y curl dnsutils <b>iptables</b>
   
   # CentOS/RHEL/Rocky/Alma
   sudo yum install -y curl bind-utils <b>iptables</b>
   ```

3. **CSV Download Issue**:
   ```bash
   sudo wget -O /usr/local/bin/speedtest_websites.csv https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/speedtest_websites.csv
   ```
   
   **Note**: If you see "CSV file downloaded successfully" but the script doesn't work, the repository might be private or inaccessible. The script now validates downloaded files to ensure they contain valid domain data (more than 5 lines and correct domain patterns).

4. **Firewall Issue**:
   ```bash
   # Check <b>iptables</b> status
   sudo <b>iptables</b> -L
   
   # Check <b>nftables</b> access
   sudo nft list tables
   ```

5. **SystemD Service Issues**:
   ```bash
   # Check service status
   sudo systemctl status speedtest-blocker
   
   # Check logs
   sudo journalctl -u speedtest-blocker -f
   ```

6. **DNS Resolution Issue**:
   ```bash
   # Test dig command
   dig +short google.com
   
   # Install if missing
   sudo apt install dnsutils  # Ubuntu/Debian
   sudo yum install bind-utils # CentOS/RHEL
   ```

## 📞 Support

- **Telegram Channel**: [@NiGmaServices](https://t.me/NiGmaServices)
- **Sponsor**: [@CloudCubeServer](https://t.me/CloudCubeServer)

## 📄 License

This project is released under the MIT License.

---

**Note**: This script is designed for server administrators and its use is the user's responsibility.