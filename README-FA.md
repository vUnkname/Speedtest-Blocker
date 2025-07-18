<div align="right" dir="rtl">

# 🚀 مسدودکننده سایت های تست سرعت / اسپید تست

</div>

> **English**: For English documentation, please refer to [this file](https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/README.md).

<div align="center">

![تصویر ترمینال](https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/screenshot.png)

</div>
<div align="right" dir="rtl">

## 📞 پشتیبانی

- **کانال تلگرام**: [@NiGmaServices](https://t.me/NiGmaServices)
- **اسپانسر**: [@CloudCubeServer](https://t.me/CloudCubeServer)

## 📝 معرفی
**Speedtest Blocker** یک اسکریپت قدرتمند برای مسدود کردن سایت‌های تست سرعت اینترنت با پشتیبانی از <b>nftables</b> و <b>nftables</b>.

## 📜 توضیحات
اسکریپت قدرتمند برای مسدودسازی سایت‌های تست سرعت اینترنت با پشتیبانی از <b>nftables</b> و <b>nftables</b>

## ✨ ویژگی‌ها

- 🔒 **مسدودسازی خودکار** سایت‌های تست سرعت (121+ سایت)
- 🔓 **رفع مسدودیت** با یک کلیک
- 🔧 **تشخیص خودکار فایروال** (<b>nftables</b>/<b>nftables</b>)
- 📊 **نمایش اطلاعات سرور** (کشور، IP، ISP)
- 🔄 **سرویس systemd** برای راه‌اندازی خودکار
- 📱 **نصب آسان** با یک دستور
- 🆕 **بروزرسانی خودکار** از ریپازیتوری
- ⏰ **بررسی روزانه** برای آپدیت فایل CSV
- 🛡️ **اعتبارسنجی فایل CSV** برای امنیت
- 🧹 **پاکسازی کامل** سیستم

## 🚀 نصب سریع

### بررسی پیش‌نیازها
```bash
# بررسی دسترسی sudo
sudo -v

# بررسی وجود curl یا wget
command -v curl || command -v wget

# بررسی سازگاری سیستم
uname -m  # باید x86_64 نمایش دهد
```

### روش 1: نصب مستقیم از اینترنت
```bash
bash <(curl -Ls https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/ST-Blocker.sh)
```

### روش 2: دانلود و اجرا
```bash
wget https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/ST-Blocker.sh
chmod +x ST-Blocker.sh
sudo ./ST-Blocker.sh
```

### روش 3: نصب دستی وابستگی‌ها ابتدا
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y curl dnsutils <b>nftables</b>

# CentOS/RHEL/Rocky/Alma
sudo yum install -y curl bind-utils <b>nftables</b>

# سپس اجرای اسکریپت
bash <(curl -Ls https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/ST-Blocker.sh)
```

## 📋 پیش‌نیازها

### نیازمندی‌های سیستم
- **سیستم عامل**: Ubuntu, Debian, CentOS, AlmaLinux, Rocky Linux
- **دسترسی**: دسترسی Root (sudo)
- **معماری**: x86_64 (64-bit)

### ابزارهای مورد نیاز (نصب خودکار)
- **curl** یا **wget** - برای دانلود فایل‌ها و درخواست‌های API
- **dig** (dnsutils/bind-utils) - برای تبدیل نام دامنه به IP
- **<b>nftables</b>** یا **<b>nftables</b>** - مدیریت فایروال
- **systemctl** - مدیریت سرویس‌های SystemD
- **jq** (اختیاری) - تجزیه JSON (در صورت عدم وجود از grep/cut استفاده می‌شود)

### دستورات سیستمی مورد استفاده
- `hostname` - دریافت IP سرور
- `awk`, `grep`, `cut` - پردازش متن
- `stat` - اطلاعات فایل
- `date` - عملیات زمان

## 🎯 نحوه استفاده

1. **اجرای اسکریپت**:
   ```bash
   sudo ST-Blocker.sh
   ```

2. **انتخاب گزینه**:
   - `1` - مسدودسازی سایت‌های تست سرعت
   - `2` - رفع مسدودیت سایت‌ها
   - `3` - بروزرسانی لیست سایت‌ها
   - `4` - پاکسازی کامل
   - `0` - خروج

## 🔄 بروزرسانی خودکار

### ✅ **بررسی خودکار هنگام اجرا:**
- اسکریپت هر بار که اجرا می‌شود، فایل CSV را بررسی می‌کند
- اگر فایل CSV بیش از 24 ساعت قدیمی باشد، آن را بروزرسانی می‌کند
- آخرین لیست سایت‌های تست سرعت از ریپازیتوری دانلود می‌شود

### 🔧 **بروزرسانی دستی:**
```bash
# اجرای اسکریپت و انتخاب گزینه 3
sudo ST-Blocker.sh

# یا بروزرسانی مستقیم فایل CSV
sudo curl -o /usr/local/bin/speedtest_websites.csv https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/speedtest_websites.csv
```

### 🚫 **غیرفعال کردن بررسی خودکار:**
```bash
# اجرا بدون بررسی بروزرسانی (نسخه 1.0.0)
sudo ST-Blocker.sh --no-update
```

**نکته**: پارامتر `--no-update` از بررسی و دانلود خودکار فایل CSV جلوگیری می‌کند و مستقیماً به منوی اصلی می‌رود.

## 📁 فایل‌های نصب شده

- **اسکریپت اصلی**: `/usr/local/bin/ST-Blocker.sh`
- **لیست سایت‌ها**: `/usr/local/bin/speedtest_websites.csv` (121 سایت)
- **سرویس systemd**: `/etc/systemd/system/speedtest-blocker.service`
- **قوانین <b>nftables</b>**: `/etc/<b>nftables</b>/rules.v4` (در صورت استفاده)

## 🔧 مدیریت سرویس

```bash
# بررسی وضعیت سرویس
sudo systemctl status speedtest-blocker

# توقف سرویس
sudo systemctl stop speedtest-blocker

# راه‌اندازی مجدد
sudo systemctl restart speedtest-blocker

# غیرفعال کردن
sudo systemctl disable speedtest-blocker
```

## 🧹 پاکسازی کامل

اسکریپت شامل گزینه پاکسازی کامل است که موارد زیر را حذف می‌کند:
- تمام قوانین <b>nftables</b> و <b>nftables</b>
- سرویس و فایل‌های SystemD
- اسکریپت نصب شده و فایل‌های CSV
- هرگونه قانون مسدودسازی باقی‌مانده

```bash
# اجرای اسکریپت و انتخاب گزینه 4
sudo ST-Blocker.sh
```

## 🛡️ امنیت

- تمام عملیات با دسترسی root انجام می‌شود
- قوانین فایروال به صورت ایمن اعمال می‌شوند
- امکان بازگردانی کامل تنظیمات

## 🔍 عیب‌یابی

### مشکلات رایج:

1. **خطای دسترسی**:
   ```bash
   sudo chmod +x /usr/local/bin/ST-Blocker.sh
   ```

2. **کمبود وابستگی‌ها**:
   ```bash
   # Ubuntu/Debian
   sudo apt update && sudo apt install -y curl dnsutils <b>nftables</b>
   
   # CentOS/RHEL/Rocky/Alma
   sudo yum install -y curl bind-utils <b>nftables</b>
   ```

3. **مشکل در دانلود CSV**:
   ```bash
   sudo wget -O /usr/local/bin/speedtest_websites.csv https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/speedtest_websites.csv
   ```
   
   **نکته**: اگر پیام "فایل CSV با موفقیت دانلود شد" را می‌بینید اما اسکریپت کار نمی‌کند، احتمالاً ریپازیتوری خصوصی یا غیرقابل دسترس است. اسکریپت اکنون فایل‌های دانلود شده را اعتبارسنجی می‌کند تا اطمینان حاصل کند که حاوی داده‌های معتبر دامنه هستند (بیش از 5 خط و الگوهای دامنه صحیح).

4. **مشکل فایروال**:
   ```bash
   # بررسی وضعیت <b>nftables</b>
   sudo <b>nftables</b> -L
   
   # بررسی دسترسی به <b>nftables</b>
   sudo nft list tables
   ```

5. **مشکلات سرویس SystemD**:
   ```bash
   # بررسی وضعیت سرویس
   sudo systemctl status speedtest-blocker
   
   # بررسی لاگ‌ها
   sudo journalctl -u speedtest-blocker -f
   ```

6. **مشکل تبدیل DNS**:
   ```bash
   # تست دستور dig
   dig +short google.com
   
   # نصب در صورت عدم وجود
   sudo apt install dnsutils  # Ubuntu/Debian
   sudo yum install bind-utils # CentOS/RHEL
   ```

## 📞 پشتیبانی

- **کانال تلگرام**: [@NiGmaServices](https://t.me/NiGmaServices)
- **اسپانسر**: [@CloudCubeServer](https://t.me/CloudCubeServer)

## 📄 مجوز

این پروژه تحت مجوز MIT منتشر شده است.

---

**نکته**: این اسکریپت برای مدیران سرور طراحی شده و استفاده از آن مسئولیت کاربر است.

</div>