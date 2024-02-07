### Explanations to use this repository scripts

- Makefile Generator 

## Using genmake in System Commands

If you want to include `genmake` in your system commands and run it from anywhere in your terminal, follow these steps:

1. Open the Bash profile file using a text editor. For example, you can use the following command :

```bash
nano ~/.bashrc
```
   
This command will open the `.bashrc` file with the nano text editor. You can also use another editor if you prefer, such as vim or gedit.

2. Add the following line to the end of the .bashrc file :

 ```bash
export PATH=$PATH:/path/to/directory/of/genmake
 ```

Replace `/path/to/directory/of/genmake` with the absolute path to the directory containing the genmake script.

3. Save your changes and close the text editor.

4. Reload your profile file to apply the changes without having to restart your session. You can use the following command :

```bash
source ~/.bashrc
```

This will load the changes made to your `.bashrc` file.
Now you should be able to run the genmake script from anywhere in your terminal simply by using its name `genmake`

-Banned-Function-Checker

Do the same as you do for genmake
