
# Windows Partition Mount Script for Linux

## Description

This Bash script simplifies the process of mounting a Windows partition (NTFS format) on Linux, even in cases of issues like hibernation or an unclean file system. It guides the user through the necessary steps to mount the partition and configures automatic mounting on startup if desired.

---

## Features

1. Automatic detection of NTFS partitions.
2. File system status check using `ntfsfix`.
3. Error handling for Windows hibernation or fast startup.
4. Automatic creation of the mount point if needed.
5. Read/Write mounting (or Read-Only if issues persist).
6. Automatic mount configuration via `/etc/fstab`.

---

## Prerequisites

- **`ntfs-3g` package installed**: Used to mount NTFS partitions in read/write mode.
  ```bash
  sudo apt update && sudo apt install ntfs-3g
  ```

---

## Usage Instructions

### 1. Run the Script
Download the script and grant it executable permissions with:
```bash
chmod +x mount_windows.sh
```
Then, run the script with:
```bash
./mount_windows.sh
```

### 2. Follow the Guided Steps
- **Select the Partition**: The script lists all detected NTFS partitions.
- **Specify a Mount Point**: If the directory does not exist, it will be created.
- **Resolve Errors**:
  - If Windows is hibernated, disable it using the following command in Windows:
    ```cmd
    powercfg /h off
    ```
  - Ensure the disk is properly shut down in Windows (not in "fast startup" mode).

### 3. Optional Automatic Mounting
The script can add the partition to the `/etc/fstab` file for automatic mounting on startup:
- The file is modified only if the user agrees.
- The UUID of the partition is used for reliable mounting.

---

## Example Output

```
===============================
   Windows Partition Mount Script   
===============================
Searching for Windows (NTFS) partitions...
Detected partitions:
sda1 ntfs 100G /mnt/windows

Enter the device name (e.g., sda1, nvme0n1p3): sda1
Enter the mount point path (e.g., /mnt/windows): /mnt/windows
Checking file system status...
Partition successfully mounted in read/write mode at /mnt/windows.
Do you want this partition to be mounted automatically at startup? (yes/no): yes
Entry successfully added to /etc/fstab.
```

---

## Troubleshooting

- **"Windows is hibernated"**:
  - Disable hibernation and fast startup in Windows.
- **"Unable to retrieve UUID"**:
  - Ensure the selected device exists and contains a valid file system.

---

## Warnings

- Modify `/etc/fstab` with caution. Errors can prevent your system from booting properly.
- Use this script only if you understand the implications of mounting NTFS partitions on Linux.

---

## Author
GNANDI Salem
