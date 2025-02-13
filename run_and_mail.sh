#!/bin/bash

# Logging function with levels and timestamp
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""
    local reset="\033[0m"

    case $level in
        "INFO")
            color="\033[0;32m"  # Green
            ;;
        "WARN")
            color="\033[0;33m"  # Yellow
            ;;
        "ERROR")
            color="\033[0;31m"  # Red
            ;;
        *)
            color="\033[0m"     # No color
            ;;
    esac

    echo -e "${color}[${timestamp}] [${level}] ${message}${reset}"
}

# Load email configuration from an external file
if [ -f config_run_and_mail.env ]; then
    source config_run_and_mail.env
else
    log_message "ERROR" "Missing config_run_and_mail.env file. Please create it with your email settings."
    log_message "INFO" "Example config_run_and_mail.env: 
EMAIL_FROM=\"sender@email.com\"
EMAIL_TO=\"reciver@email.com\""
    exit 1
fi

# Check if a command was provided
if [ $# -eq 0 ]; then
    log_message "ERROR" "No command provided"
    log_message "INFO" "Usage: $0 'command_to_execute'"
    exit 1
fi

# Function to display a spinner while a process is running
show_spinner() {
    local pid=$1
    local delay=0.75
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local start_time=$SECONDS

    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        local elapsed=$(( SECONDS - start_time ))
        printf "\r\033[K[%s] Proceso en ejecución... %02d:%02d" "${spinstr:0:1}" $(($elapsed/60)) $(($elapsed%60))
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r\033[K"
}

# Function to send an email notification
send_notification_email() {
    local email_content="$1"
    local temp_mail="/tmp/mail_${TIMESTAMP}.html"
    
    # Save the email content to a temporary file
    echo -e "$email_content" > "$temp_mail"
    
    # Attempt to send the email and capture the result
    if ! msmtp apocrb23@gmail.com < "$temp_mail" 2>/tmp/mail_error_${TIMESTAMP}.log; then
        local error=$(cat /tmp/mail_error_${TIMESTAMP}.log)
        log_message "ERROR" "❌ Failed to send email: $error"
        
        # Save a copy of the failed email
        local backup_file="$LOG_DIR/failed_mail_${TIMESTAMP}.html"
        mv "$temp_mail" "$backup_file"
        log_message "INFO" "💾 Email saved at: $backup_file"
        
        # Attempt to send a simplified email without the log content
        local retry_content="From: $EMAIL_FROM
To: $EMAIL_TO
Subject: [🟠 URGENT] Process Notification Failed
Content-Type: text/plain; charset=UTF-8

The process email notification failed with exit status $EXIT_STATUS.
The detailed email could not be sent.
Details are available at: $backup_file"

        if ! echo -e "$retry_content" | msmtp $EMAIL_TO 2>/dev/null; then
            log_message "ERROR" "❌ Failed to send even the simplified email"
            return 1
        else
            log_message "WARN" "⚠️ Sent a simplified email notification"
        fi
    else
        log_message "INFO" "📩 Email sent successfully to $EMAIL_TO"
        rm -f "$temp_mail"
    fi
    
    # Cleanup
    rm -f "/tmp/mail_error_${TIMESTAMP}.log"
    return 0
}

# Extract the first word of the command to use in the log filename
CMD_NAME=$(echo "$1" | awk '{print $1}')
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

LOG_DIR="$HOME/run_and_mail_logs"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/log_${CMD_NAME}_${TIMESTAMP}.log"
SAR_LOG_FILE="$LOG_DIR/sar_${CMD_NAME}_${TIMESTAMP}.log"

# Check if `sar` is installed
if ! command -v sar &> /dev/null; then
    log_message "WARN" "sar is not installed. Install sysstat to enable system load tracking."
    AVG_LOAD="N/A (sar not installed)"
else
    # Start temporary `sar` logging every second (No sudo required)
    sar -o "$SAR_LOG_FILE" 1 > /dev/null 2>&1 &
    SAR_PID=$!
fi

# Track execution time
START_TIME=$SECONDS

# Run the command in the background and save the log
/usr/bin/time -v nohup bash -c "$1" > "$LOG_FILE" 2>&1 &
PID=$!

# Debugging
log_message "INFO" "📌 Log file: $LOG_FILE"
log_message "INFO" "🚀 Starting Process: $1"
log_message "INFO" "🔍 Process ID: $PID"
log_message "INFO" "-----------------------------------------"

# Show spinner while waiting for process
log_message "INFO" "⏳ Waiting for the process to complete..."
show_spinner $PID &
SPINNER_PID=$!
wait $PID
EXIT_STATUS=$?
kill $SPINNER_PID 2>/dev/null
echo ""

# Capture execution time
EXECUTION_TIME=$(( SECONDS - START_TIME ))

# Stop temporary `sar` logging
if [ -n "$SAR_PID" ]; then
    kill "$SAR_PID" 2>/dev/null
fi

# Compute the average load during execution using sar logs
if [ -f "$SAR_LOG_FILE" ]; then
    AVG_LOAD=$(sar -q -f "$SAR_LOG_FILE" | awk 'NR>2 {sum+=$4; count++} END {if (count>0) print sum/count; else print "N/A"}')
else
    AVG_LOAD="N/A (sar log missing)"
fi

# Define total CPU threads
CPU_THREADS=12  # Ryzen 5 3600 has 12 threads

# Convert raw load to percentage
if [[ "$AVG_LOAD" != "N/A" ]]; then
    NORMALIZED_LOAD=$(echo "scale=2; ($AVG_LOAD / $CPU_THREADS) * 100" | bc)
else
    NORMALIZED_LOAD="N/A"
fi

# Capture system load at the time of execution
SYSTEM_LOAD=$(uptime)

# Check if the command was successful
log_message "INFO" "-----------------------------------------"
if [ $EXIT_STATUS -eq 0 ]; then
    SUBJECT="[✅ SUCCESS] ${CMD_NAME} - Completed in ${EXECUTION_TIME}s"
    STATUS_MSG="The command completed successfully."
    log_message "INFO" "✅ SUCCESS: The command finished without errors."
else
    SUBJECT="[❌ FAILED] ${CMD_NAME} - Error after ${EXECUTION_TIME}s"
    STATUS_MSG="The command encountered an error."
    log_message "ERROR" "❌ ERROR: The command failed. Check the log file for details."
fi

# Debugging
log_message "INFO" "🔚 Process $PID finished with exit status: $EXIT_STATUS"
log_message "INFO" "⏱️ Execution time: $EXECUTION_TIME seconds"
log_message "INFO" "📊 System Load: $SYSTEM_LOAD"
log_message "INFO" "📈 Average System Load during execution: $AVG_LOAD"
log_message "INFO" "💻 CPU Load Normalized: $NORMALIZED_LOAD%"

# Read log content and escape special HTML characters
LOG_CONTENT=$(cat "$LOG_FILE" | sed 's/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g')

# Send email notification with log file and execution metrics
EMAIL_CONTENT="From: $EMAIL_FROM
To: $EMAIL_TO
Subject: $SUBJECT
Content-Type: text/html; charset=UTF-8

<html>
<body>
<h2>$SUBJECT</h2>
<p><strong>Command:</strong> $1</p>
<p><strong>Status:</strong> $STATUS_MSG</p>
<p><strong>Log File:</strong> <code>$LOG_FILE</code></p>

<h3>Execution Metrics:</h3>
<ul>
<li><strong>Execution Time:</strong> $EXECUTION_TIME seconds</li>
<li><strong>System Load:</strong> $SYSTEM_LOAD</li>
<li><strong>Average System Load during execution:</strong> $AVG_LOAD</li>
<li><strong>CPU Load Normalized:</strong> $NORMALIZED_LOAD%</li>
</ul>

<h3>Log Output:</h3>
<div style='background-color: #f4f4f4; padding: 10px; border: 1px solid #ddd; max-height: 300px; overflow: auto; font-family: monospace; white-space: pre-wrap;'>
$LOG_CONTENT
</div>

<p>End of log.</p>
</body>
</html>"

# Enviamos el correo y manejamos errores
if ! send_notification_email "$EMAIL_CONTENT"; then
    log_message "ERROR" "❌ Fallo en el proceso de notificación por correo"
    # Guardamos una copia local del log
    cp "$LOG_FILE" "$LOG_DIR/failed_notification_${TIMESTAMP}.log"
fi

rm -f "$SAR_LOG_FILE"  # Clean up temporary sar log file