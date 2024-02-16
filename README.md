# Using Scripts in this Repository

This repository contains Bash and Python scripts designed to automate certain boring tasks. Here's how to use them:

## Granting Permissions to the Scripts

Before running the scripts, ensure they have the appropriate permissions to be executed. You can use the chmod command for this:

```bash
chmod +x script.sh script.py
```

This grants execution rights to the script.sh and script.py files.

## Installing Dependencies (if necessary)

Some scripts may have external dependencies. Make sure to install them using the appropriate package managers. For example, if your script uses Python packages, you can install them with pip:

```bash
pip install -r requirements.txt
```

Make sure you have Python and pip installed on your system.

## Configuring the Path in the bashrc file (optional)

If you want to run these scripts from anywhere in your system without specifying the full path, you can add the directory containing the scripts to your PATH environment variable. To do this, edit your .bashrc or .bash_profile file:

```bash
export PATH=$PATH:/path/to/your/repo/scripts
```

Make sure to replace /path/to/your/repo/scripts with the absolute path to the directory containing your scripts.

Finally, remember to refresh your .bashrc file for changes to take effect. You can do this by sourcing the file:

```bash
source ~/.bashrc
```
