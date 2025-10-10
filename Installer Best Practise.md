# Installer Best Practise

This document is for people that create apps/packages for Initra. To keep things from breaking and as unified as possible there are some "best practises". It highly depends on what you're trying to do so they may not apply to your situation.

------

## Installing and running Apps

Generally its recommended to use the `root` user when trying to install apps/packages. Its also recommended to create separate users for separate applications for security reasons. If your script installs a minecraft spigot server its best to also add a user, like `minecraft` to run this server after installation instead of using the root user.

### Where to install apps

You can find helpful functions and other code inside the `snippets` folder. For creating users there is a `adduser.sh` file with a function `create_initra_app_user` that you can copy-paste in your install script.

The idea of the `create_initra_app_user` function is to have "standalone"[^1] apps united at one place, in this case `/home/initra/<app_name>` while still having them user-separated for security reasons. Other applications[^2] may not require that.

This means when you add a user using `create_initra_app_user "minecraft"`, it'll create and set the users home directory to `/home/initra/minecraft`. 

You could also use app arguments inside your install script to create sub-directories inside the `/minecraft` folder to be able to run multiple servers at once. Again, **it highly depends on what you're trying to do**.

> [!NOTE]
>
> **The goal** behind this is to avoid "spamming" app folders inside the `/home` folder when someone installs many apps using Initra.

 

------

## Checks and execution

### Repeated Execution

What would happen if a user would try to install your app/package **again**? Would it try to install and setup everything again? Would it overwrite existing configurations? Its important to check inside your install script (`install.sh`) for many different things depending on what you're trying to achieve.

If you try to install a minecraft spigot server, you may check first if there is already a `minecraft` folder inside the `/home/minecraft` folder, or if your script uses arguments for sub-directories, to check if said server already exists *(you get the idea)*.

If it already exists you could exit the script early. This concept applies to other applications too. If a user tries to install mysql again, you **should** check first if its already installed on the system and if so, you exit the script.

Certain applications can be updated with this concept. If you try to install TeamSpeak³ and it already exists, you could update it and exit afterwards. The possibilities are endless and the install script is very flexible.

### Checks

Its important your script doesnt blindly run its code. Its recommended to add OS checks and similar checks so that if someone tries to install your app on a linux distro that has different commands it doesnt crash or possibly do weird things.

Another example is using `sudo` in your script while sudo may not even be installed on the SSH host.

------

## Loading external scripts

Its generally discouraged to load other script files from your install script if the sources arent well known. This is done to prevent malicious code from running on a server and to protect the users using Initra.

> [!NOTE]
>
> Loading files from the `snippets` folder is totally fine.

------

## Avoiding duplicates

To avoid having two or more apps/packages having to implement their own way on how to install another app first i've created a app dependency feature.

For example two apps/packages, phpMyAdmin and some NodeJS project,  require MariaDB to be installed. Instead of both having to implement the installation of MariaDB themselves, they could set MariaDB as a dependency that'll be installed before their own app installer runs.

This is done to prevent possible conflicts and to save time for developers. You can specify MariaDB in your dependency and just focus on installing the app itself, like phpMyAdmin.

> [!NOTE]
>
> This example assumes there already is a MariaDB installer app. If the app MariaDB doesnt exist you wont be able to use it as dependency.





[^ 2]: Applications like mysql, fail2ban that can be easily detected or found
[^1]: Software like NodeJS projects, a mincraft spigot server, etc that can run in any folder and or are hard to find/detect