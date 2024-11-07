
# Using Scripts in this Repository

This repository contains a collection of Bash and Python scripts that automate common tasks to save time and improve efficiency. Here's a guide on how to set up and use these scripts.

## Granting Permissions to the Scripts

Before running any script, you need to ensure that they have the appropriate permissions to execute. To grant execution rights, use the following command:

```bash
chmod +x script.sh script.py
```

This will give execution rights to `script.sh` and `script.py`. Make sure you adjust the script names based on the actual scripts in your repository.

## Installing Dependencies (if necessary)

Some scripts might rely on external dependencies. If your script has a `requirements.txt` file, you can install the required Python packages using `pip`:

```bash
pip install -r requirements.txt
```

Ensure that you have Python and `pip` installed on your system. For system-specific dependencies, like `valgrind`, they will be handled within the scripts, but make sure your system has the required tools.

## Running Scripts as Root (if necessary)

Some scripts may require root privileges. If you're running a script that needs `sudo` access, you will need to ensure you execute it with the appropriate permissions:

```bash
sudo ./script.sh
```

If the script isn't run with root privileges, it will prompt you to use `sudo` or show an error.

## Installing System Dependencies (if necessary)

If your script needs system tools like `valgrind` and it’s not installed, the script will automatically prompt you to install them. For example, on a Debian-based system, it will guide you to install using `apt`:

```bash
sudo apt-get update
sudo apt-get install valgrind
```

For other distributions, the script will suggest the appropriate package manager (`dnf`, `yum`, `pacman`, etc.).

## Configuring the Path for Easy Access (Optional)

To run the scripts from anywhere on your system without specifying the full path, you can add the directory containing the scripts to your system's `PATH` environment variable.

Edit your `.bashrc` or `.bash_profile` file by adding the following line:

```bash
export PATH=$PATH:/path/to/your/repo/scripts
```

Replace `/path/to/your/repo/scripts` with the actual absolute path to the directory where your scripts are located.

Once you've edited the file, refresh it by sourcing the `.bashrc`:

```bash
source ~/.bashrc
```

## Script Usage

- **Banned-function-checker**: Checks for the usage of banned functions in your code.
- **Makefile Generator**: Automatically generates a `Makefile` for your project.
- **Push_that**: Pushes changes to the repository, including staging and committing files.
- **Repo_organiser**: Organizes your repository by grouping files into their respective directories.
- **Valgrind_memory_checker**: Runs `valgrind` to check memory usage and potential memory leaks in your compiled code.

Refer to each script's individual documentation within the repository for specific usage instructions and features.

---

Enjoy automating your tasks with these scripts! Feel free to contribute or create new ones to extend the functionality.