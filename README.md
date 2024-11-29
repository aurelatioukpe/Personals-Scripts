# Automation Scripts Repository

This repository contains a collection of Bash and Python scripts designed to automate common tasks, saving time and improving efficiency. Below is a guide to set up, use, and contribute to these scripts.
Scripts Available in This Repository

- **Banned-Function-Checker** : Checks for banned functions in your code.
- **Makefile Generator** : Automatically generates a Makefile for your project.
- **Push_That** : Automates the process of pushing changes to the repository.
- **Repo_Organiser** : Organizes your project directory by grouping files appropriately.
- **Valgrind Memory Checker** : Runs valgrind to check memory usage and detect memory leaks in your compiled code.
- **Windows Mount** : A script to mount NTFS partitions from Windows to Linux with auto-mount configuration.

For detailed instructions on using each script, refer to the **individual README files** inside the corresponding directories.
## Installation and Setup
1. **Granting Permissions to Scripts**

Before using any script, ensure that it has execution permissions. Use the following command to grant the necessary permissions:
```bash
chmod +x script.sh
```
Replace script.sh with the actual script name.

2. **Installing Dependencies**

Some scripts may have dependencies. If a script includes a requirements.txt file, you can install the necessary Python packages by running:
```bash
pip install -r requirements.txt
```
For system dependencies (e.g., valgrind), the script will prompt you for installation if necessary.

3. **Running Scripts as Root (if needed)**

Some scripts require root privileges. If prompted, run the script with sudo:
```bash
sudo ./script.sh
```

## Adding a New Script

To add a new script to this repository:

- Create a new folder under the main directory for your script.
- Include your script file and a README.md file explaining the script's functionality and usage.
- Ensure your script includes any necessary dependency management (e.g., requirements.txt for Python scripts or installation instructions for system tools).
- Update this README.md with a description of the new script in the "Scripts Available in This Repository" section.

Once you've created your script, please submit a pull request for review.

## Contact

If you encounter any issues or have questions about the scripts, feel free to contact the repository owners:

- aurel.atioukpe@epitech.eu
- salem.gnandi@epitech.eu

## Disclaimer

These scripts are provided "as is" without any warranties. Use at your own risk. The repository owner is not responsible for any damage or data loss that may occur as a result of using these scripts.