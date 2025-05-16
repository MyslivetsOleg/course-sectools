#!/bin/bash
total_score=0
task2_userdir="/opt/backups"
task_user="backup-operator"
logfile="/var/log/sudo/backup-operator.log"
auditd_file="backup.rules"
auditd_label="backup_monitoring"
## check task 1 tmp mounted as  tmpfs with noexec option
sudo usermod -aG systemd-journal srvadmin
sudo usermod -aG root srvadmin
task-1(){
	mountpoint=$(findmnt | grep /tmp | sed 's/\\n/ /')
	if ! [[ -n $mountpoint ]]; then
		printf "[-] T1 - No existing tmp mountpoint found! Exiting task check! \n"
		return 1
	fi
	printf "[+] T1 - Existing tmp mountpoint found at %s \n" "$mountpoint"

	#check `mountpoint` for correct fs
	if [[ "$mountpoint" == *tmpfs* ]]; then
		printf "[+] T1 - Mountpoint has correct fs type, +points \n"
		(( total_score += 7 ))
	fi
	#check `noexec` option
	if [[ "$mountpoint" == *noexec* ]]; then
		printf "[+] T1 - Mountpoint has correct mount options, +points \n"
		(( total_score += 7 ))
	fi
}


## check task 2 - user `backup-operator` created + group created
task-2(){
	bo_user=$(cat /etc/passwd | grep backup.operator)
	bo_group=$(cat /etc/group | grep backup.operator)
	if ! [[ -n $bo_user || -n $bo_group ]]; then
		printf "[-] T2 - Required user and group do not found! Exiting futher task checks! \n"
		return 1
	fi
	if [[ -n $bo_user ]]; then
		printf "[+] T2 - Required user exists, +points \n"
		(( total_score += 7 ))
	fi
	if [[ -n $bo_group ]]; then
		printf "[+] T2 - Required group exists, +points \n"
		(( total_score += 7 ))
	fi
	if [[ -d "$task2_userdir" ]]; then
		printf "[+] T2 - Required user home directory exists, +points \n"
		(( total_score += 7 ))
	fi
}

## check task 3 - acl for user student to allow read/write over /opt/backups
task-3(){
	acl=$(getfacl "$task2_userdir" 2>/dev/null)
	if ! [[ -n $acl ]]; then
		printf "[-] T3 - Required acl entry do not found! Exiting futher task checks! \n"
		return 1
	fi
	touch "$task2_userdir/testfile" 2>/dev/null
	if [[ "$acl" == *student* &&  \
	       	$? -eq 1 && \
               	$(stat -c '%U' "$task2_userdir") == "$task_user" && \
               	$(stat -c '%G' "$task2_userdir") == "$task_user" ]]; then
		printf "[+] T3 - Required acl entry works correct, +points \n"
		(( total_score += 14 ))
	fi

}

## check task 4 - ssh keys
task-4(){
	stat "$task2_userdir/.ssh/authorized_keys" 2>/dev/null
	if [[ $? -gt 0 ]]; then
		printf "[-] T4 - Authorized Keys file not found! Exiting futher task checks! \n"
		return 1
	else
		printf "[+] T4 - AuthKyes file found, +points \n"
		(( total_score += 7 ))
	fi
	login_attempt=$(journalctl -xe -t sshd | grep "$task_user")
	if [[ -n "$login_attempt" ]]; then
		printf "[+] T4 - Login attempt found in logs, +points \n"
		(( total_score += 7 ))
	fi
}

# check task-5 sudo configuration
task-5(){
	stat "/etc/sudoers.d/$task_user" 2>/dev/null
	if [[ $? -gt 0 ]]; then
		printf "[-] T5 - Required sudoers.d drop-in do not found! Exiting futher task checks! \n"
		return 1
	else
		printf "[+] T5 - Drop-in for sudo found! +points \n"
		(( total_score += 7 ))
	fi
	sudo_file=$(cat /etc/sudoers.d/"$task_user")
	if [[ $sudo_file == *NOPASSWD*.bash* ]]; then
		printf "[+] T5 - Required sudo entry found! +points! \n"
		(( total_score += 7 ))
	fi
}

# check task-6 sudo logging
task-6(){
	sudo_file=$(cat /etc/sudoers.d/"$task_user" 2>/dev/null)
	if [[ $? -gt 0 ]]; then
		printf "[-] T6 - Required  file do not found! Exiting futher task checks! \n"
		return 1
	fi
	if [[ $sudo_file == *backup-operator*logfile* ]]; then
		printf "[+] T6 - Required log entry found! + points! Exiting futher task checks! \n"
		(( total_score += 7 ))
	fi
	log_entry_count=$(wc -l "$logfile" 2>/dev/null | awk '{print $1}')
	if [[ $log_entry_count -gt 0 ]]; then
		printf "[+] T6 - Sudo log entries found! +points! \n"
		(( total_score += 7 ))
	fi
}

# check task-7 auditd
task-7(){
	auditd_file=$(cat /etc/audit/rules.d/"$auditd_file" 2>/dev/null)
	# echo "$auditd_file"
	if [[ $? -gt 0 ]]; then
		printf "[-] T7 - Required file do not found! Exiting futher task checks! \n"
		return 1
	fi
	rule_mask="-w $task2_userdir -p * -k $auditd_label"
	# echo "$rule_mask"
	if [[ $auditd_file == $rule_mask ]]; then
		printf "[+] T7 - Required auditd entry found! +points! \n"
		(( total_score += 7 ))
	else
		printf "[-] Possible incorect rule! Exiting futher task checks! \n"
		return 1
	fi
	log_entry_count=$(sudo cat /var/log/audit/audit.log 2>/dev/null | grep -c 'name="/opt/backups/"')
	if (( log_entry_count > 0 )); then
		printf "[+] T7 - Log file entries found! +points! \n"
		(( total_score += 7 ))
	fi
}

task-1
task-2
task-3
task-4
task-5
task-6
task-7
printf "[Result]: Total Score=%d \n" $total_score
