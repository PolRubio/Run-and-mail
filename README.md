# 📩 Run and Mail

A **Bash script** that runs a command, **tracks execution time and system load**, and sends an **email notification** with detailed logs at the end. Perfect for **automated task monitoring** and **email alerts**.  

---

## **🚀 Key Features**  

✔ **Command Execution Tracking** – Logs runtime, system load, and exit status.  
⏳ **Live Spinner Animation** – Displays a progress spinner while the process runs.  
📨 **Automated Email Notifications** – Sends an email summary with system metrics.  
📊 **CPU Load & System Performance Tracking** – Uses `sar` to measure system load dynamically.  
🔍 **Secure Configuration** – Uses `.env` file to store email settings, keeping credentials private.  
🛠 **Error Handling & Logging** – Color-coded logs for debugging and troubleshooting.  

---

## **📥 Getting Started**  

### **🔹 Prerequisites**  

Before using **run-and-mail**, ensure the following dependencies are installed:  

- **msmtp-mta** – For sending email notifications.  
- **sysstat** – For system monitoring (`sar` command).  
- **bc** – For CPU load calculations.  

🔹 **Install Dependencies (Ubuntu/Debian)**  
```bash
sudo apt install msmtp-mta sysstat bc -y
```

🔹 **Install Dependencies (CentOS/RHEL)**  
```bash
sudo yum install msmtp sysstat bc -y
```

---

## **🛠 Installation**  

1️⃣ **Clone the Repository**  
```bash
git clone https://github.com/PolRubio/run-and-mail.git
cd run-and-mail
chmod +x run_and_mail.sh
```

2️⃣ **Create a `.env` File for Email Configuration**  

To configure email notifications, create a `.env` file named **`config_run_and_mail.env`** inside the script directory:  

```ini
EMAIL_FROM="your-email@example.com"
EMAIL_TO="receiver@example.com"
```

3️⃣ **Prevent Accidental Upload of Sensitive Data**  

Before pushing to GitHub, **add the config file to `.gitignore`**:  

```bash
echo "config_run_and_mail.env" >> .gitignore
```

Now, your email settings remain private! 🔒  

---

## **📌 Usage**  

To track a command and receive an **email notification** when it completes, run:  
```bash
./run_and_mail.sh "your_command_here"
```

### **🔹 Example Usage:**  
```bash
./run_and_mail.sh "python3 my_script.py"
```

This will:  
- Execute **`python3 my_script.py`**.  
- Show a **spinner animation** while the script runs.  
- Capture system load (`sar`), execution time, and CPU usage.  
- Send an **email summary** when the command completes.  

---

## **📊 System Tracking & Logging**  

The script automatically:  
✔ **Tracks execution time** and CPU load.  
✔ **Logs system status before and after execution**.  
✔ **Stores execution logs in `$HOME/run_and_mail_logs`**.  

🔹 **Live system load monitoring using `sar`:**  
- Collects **CPU usage and system load** during execution.  
- Normalizes CPU usage based on **total CPU threads**.  

### **📈 Sample Email Report (HTML Format)**  
- Execution Time: **32 seconds**  
- System Load: **0.45, 0.55, 0.60**  
- CPU Load Normalized: **12.5%**  

> **Want to keep execution logs?**  
> Logs are saved in `$HOME/run_and_mail_logs/log_<COMMAND>_<TIMESTAMP>.log`.  

---

## **🛠 Troubleshooting**  

### **1️⃣ Email Not Sending?**  
- Ensure `msmtp` is configured properly (`~/.msmtprc`).  
- Check for email errors in `/tmp/mail_error_*.log`.  

### **2️⃣ `sar` Not Found?**  
- Install `sysstat`:  
  ```bash
  sudo apt install sysstat -y
  ```

### **3️⃣ Command Execution Failing?**  
- Ensure the command is **wrapped in quotes**:  
  ```bash
  ./run_and_mail.sh "ls -l /home/user"
  ```

---

## **📜 License**  
This project is licensed under the **MIT License**.  

---

## **👨‍💻 Contributing**  

We welcome contributions! If you have feature ideas or improvements:  

1️⃣ **Fork the repository**  
2️⃣ **Create a feature branch** (`git checkout -b feature-new-idea`)  
3️⃣ **Commit your changes** (`git commit -m "Added feature XYZ"`)  
4️⃣ **Push to GitHub** (`git push origin feature-new-idea`)  
5️⃣ **Open a pull request!** 🚀  

### **💡 Have a Future Improvement Idea?**  
If you have an **idea for a new feature** or an **improvement**, please **open an issue** in the repository explaining:  
✔ **What the improvement is**  
✔ **Why it’s useful**  
✔ **Any implementation suggestions**  

This helps to keep track of new feature requests and discuss them before development.  

---

💡 **Created by [Pol Rubio](https://github.com/PolRubio) – Contributions Welcome!** 🎯🔥  
