# Using Docker to Build the RZ/G2 BSP

The RZ/G BSPs are distributed as Yocto builds. However, Yocto versions are limited to what host OS version you can use.

Below are the Linux PC hosts that the BSPs are tested with. Using a version other than these is not recommended.

* Yocto 3.1 Dunfell should be built with Ubuntu 20.04.
* Yocto 2.4 Rocko should be built with Ubuntu 18.04 (recommended) or Ubuntu 16.04.

A docker container will allow you to replicate the same build environment (Ubuntu OS version) without having to modify your current running host OS version.
These instructions explain how to install and set up docker so that you can build the BSP inside a docker container of the correct Ubuntu version.

The container only requires 1GB - 2GB of hard drive space. So it is much more efficient than installing a complete virtual machine. Additionally, using the instructions we will explain here, you will get to keep all your build files in your existing file system making them easy to access (as opposed to hidden inside a virtual machine).

## 1. About Docker
A Dockerfile describes the contents of a Docker image, and a Docker container is an instance of the image. Docker
containers share the host's kernel but have their own root file system as specified in a Dockerfile. This allows you to
run applications that require a specific version of an OS on a host with a different OS. It ensures that your
environment is not polluted with other installed packages and it allows you to ensure that an application works
with just the packages specified in the Dockerfile.

### 1.1 Images vs Containers
In Docker, you create 'Containers' which are running instances of 'Images'. They don't change the original image (it's like a clone).
But, if you want to save/transfer that container to another machine, or make another container using a current container as a starting point, you have to first 'commit' that container back to an 'image' file.
Note that many command line options/features are only available when you first create the container. If you missed something, you'll have to recreate the container from scratch again.

### 1.2 Files and Directories Inside vs Outside the Container
When you operate inside a docker container, the entire container file system is isolated (contained) from the host system's file system. You can imagine from a security standpoint, this is very helpful. However, if your entire BSP build environment is located inside this container, you **will not** be able to access it from your normal Ubuntu Desktop environment. That will make things more difficult for you!

Therefore, you should choose a location on your host machine that will be accessible from **both** inside and outside of your docker container. Like a **shared directory**.

I suggest using the **same path** for both inside and outside. For example, if you make a directory called "yocto" off your home directory and then that directory will be accessible from inside the docker container.
<br>
&emsp; Host PC environment : /home/chris/yocto <br>
&emsp; Inside docker container : /home/chris/yocto
<br> In this case, you would pass the following command line option : --volume=/home/chris/yocto:/home/chris/yocto


### User Accounts Inside vs Outside the Container

Users inside a docker container are different to the host users. We usually want to access files outside the container, but if you create files in your docker container, they will belong to a different UID.

You can use the "--user=$(id -u):$(id -g)" option to set the UID, however, that then causes problems with the root access within the container.

A good overview of the problems is [here](https://jtreminio.com/blog/running-docker-containers-as-current-host-user/#ok-so-what-actually-works).

There is a way to run your Docker container with the same user ID and permissions as you have on the host.
Docker allows you to 'overlay' directories from the host within the container.
Doing so for the directories involved with ID and permissions makes your container behave the same as the host, see this



## 2. Docker Install

### 2.1 Follow the Instructions on the Docker Website

The Docker installation packages available in the official Ubuntu repositories may not be the latest version.

To ensure you get the latest version, it is better to install Docker from the official Docker repository.

The instructions on the docker website are very easy to follow. They are simply copy/paste.
We recommend to use the  [Install using the apt repository](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository) method.
* https://docs.docker.com/engine/install/ubuntu

### 2.2 Check if docker is running
<pre>
$ sudo systemctl status docker --no-pager
</pre>
Here is what you will see:
<pre>
chris$ sudo systemctl status docker --no-pager
● docker.service - Docker Application Container Engine
     Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2023-03-20 17:06:04 EDT; 4min 53s ago
TriggeredBy: ● docker.socket
       Docs: https://docs.docker.com
   Main PID: 1403652 (dockerd)
      Tasks: 22
     Memory: 28.5M
        CPU: 732ms
     CGroup: /system.slice/docker.service
             └─1403652 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock

Mar 20 17:06:03 lenovo-p330 dockerd[1403652]: time="2023-03-20T17:06:03.745478376-04:00" level=info msg="successfully migrated engine ID"
Mar 20 17:06:03 lenovo-p330 dockerd[1403652]: time="2023-03-20T17:06:03.745999477-04:00" level=info msg="Loading containers: start."
Mar 20 17:06:04 lenovo-p330 dockerd[1403652]: time="2023-03-20T17:06:04.501721035-04:00" level=info msg="Default bridge (docker0) is assigned with an …IP address"
Mar 20 17:06:04 lenovo-p330 dockerd[1403652]: time="2023-03-20T17:06:04.619526298-04:00" level=info msg="Loading containers: done."
Mar 20 17:06:04 lenovo-p330 dockerd[1403652]: time="2023-03-20T17:06:04.650188695-04:00" level=info msg="Docker daemon" commit=bc3805a graphdriver=ove…sion=23.0.1
Mar 20 17:06:04 lenovo-p330 dockerd[1403652]: time="2023-03-20T17:06:04.650327945-04:00" level=info msg="Daemon has completed initialization"
Mar 20 17:06:04 lenovo-p330 dockerd[1403652]: time="2023-03-20T17:06:04.677493145-04:00" level=info msg="[core] [Server #7] Server created" module=grpc
Mar 20 17:06:04 lenovo-p330 systemd[1]: Started Docker Application Container Engine.
Mar 20 17:06:04 lenovo-p330 dockerd[1403652]: time="2023-03-20T17:06:04.681668958-04:00" level=info msg="API listen on /run/docker.sock"
Mar 20 17:07:07 lenovo-p330 dockerd[1403652]: time="2023-03-20T17:07:07.853245569-04:00" level=info msg="ignoring event" container=011f6b4af0addd88ac3…TaskDelete"
Hint: Some lines were ellipsized, use -l to show in full.
</pre>

### 2.3 Add yourself to docker group
This is so you do not have to 'sudo docker' every time to run docker.
This is not a technical required, but it is highly recommended.

<pre>
$ sudo usermod -a -G docker ${USER}
</pre>

Then, completely **log out** of your account and log back in (or you could run "$ su - ${USER}"  to avoid having to logout/reboot just  this one time)

Check that you are part of the docker group now:

<pre>
$ id -nG | grep docker
</pre>

Verify that you can run docker commands without sudo.
<pre>
 docker run hello-world
</pre>

Docker install is complete.

You can find other configuration here: https://docs.docker.com/engine/install/linux-postinstall/


## 3. Create an Image using a Dockerfile (Recommended)
The easiest way to create a Ubuntu container with everything you need to build the BSP is to use a "dockerfile" created by Renesas.

A dockerfile is like a script that will automate entering command configuring your container.

### 3.1 Build an Image

First we need to build an docker "Image". We will use a default Ubuntu image from Docker Hub as the staring point.

To create this image, we will use a "dockerfile" which is a set of commands that will set up our container for us.<br>
The full step by step instructions of what the dockerfile did is explained at the end this document if you are interested.

Copy/Paste the lines below and change them how you need.

* You may change the tag name "rz\_ubuntu-20.04" to whatever you want.
* **Select and download the dockerfile from this repository** that matches the Ubuntu version you wish to install:
 * "Dockerfile.rzg\_ubuntu-20.04"
 * "Dockerfile.rzg\_ubuntu-18.04"
 * "Dockerfile.rzg\_ubuntu-16.04"
* The docker file will download a minimal version of the Ubunut version you need, and will also install any additional packages needed to build the Renesas BSP.
* The dockerfiles are just text files, so feel free to open them up and see what they are doing.

<pre>
docker build --no-cache \
  --build-arg "host_uid=$(id -u)" \
  --build-arg "host_gid=$(id -g)" \
  --build-arg "USERNAME=$USER" \
  --build-arg "TZ_VALUE=$(cat /etc/timezone)" \
  --tag rz_ubuntu-20.04 \
  --file Dockerfile.rzg_ubuntu-20.04  .
</pre>

Confirm your image was created.

<pre>
$ docker images
REPOSITORY           TAG       IMAGE ID       CREATED          SIZE
rz_ubuntu-20.04      latest    960cf1be32b0   57 seconds ago   1.25GB
</pre>


### 3.2 Start a Container using our Image

Now that we have created our docker image, we can start a container based off that image.

Here is an explanation of each argument. Pay special attention to the "--volume" argument because you want your older Ubuntu OS to run inside the container, but want to keep all your build files outside of the container.

* **docker run** : Run a processes in isolated container
* **-it** : Starts a command shell inside your container so you can interact with it
* **--name=xxxx** : Chooses a name for your container
* **--volume=xxxx:xxxx** : Please choose a directory on your host machine that you want to map inside your container to use as your shared directory.
* **--workdir=xxxx** : You may choose a default directory where you want to start inside your container. For example, you can choose you shared directory.

<pre>
mkdir -p /home/$USER/yocto

docker run -it \
  --name=my_container_for_20.04 \
  --volume="/home/$USER/yocto:/home/$USER/yocto" \
  --workdir="/home/$USER" \
  rz_ubuntu-20.04
</pre>

You will now be running in a command line shell inside your container.

Now exit (stop) your container by typing "exit". <br>

<pre>
chris@(docker)$ exit
</pre>

Next we will explain more about how to use your container.

## 4. Using your Container

### 4.1 Start your Container Running
Containers must be running before you can enter and use them.<br>
If it is stopped, it will not show up when running the 'docker ps' command.<br>
After each system restart, you will need to start up your container again. You can use 'docker ps -a' if you've forgotten the name or ID of your containers.

This command will show you all your **running** containers
<pre>
$ docker ps
</pre>

This command will show you **all** your containers (running and stopped)
<pre>
$ docker ps -a
</pre>

Use this command to **start** your container. Use the name you gave it during the "docker run" command.<br>
You can use the 'docker ps' command to confirm it is up and running.
<pre>
$ docker start my_container_for_20.04
$ docker ps
</pre>


### 4.2 Enter Back Into Your Running Container

During the creation and setup of your container, you created a user account with the same name as your host machine.<br>
When entering into your container, use that user account (not root).
What the command 'docker exec -it /bin/bash' does it start up a command shell inside your running container.
<pre>
$ docker exec -it my_container_for_20.04 /bin/bash
</pre>

### 4.2 Exit the Container

Since you are just running a bash shell inside your container, you can type 'exit' to leave your container.


<pre>
$ exit
</pre>

### 4.3 Using tmux Inside the Container

When running inside a docker container, some graphical interfaces like "menuconfig" will not display correctly because the "terminal" you are executing commands is not a standard terminal and some things will not display correctly.

However, you can run 'tumx' which emulates a standard terminal and then things (like menuconfig) will all look correct inside your container.

Simply run this command each time you enter the container (before you start to do any Yocto work)

<pre>
$ tmux
</pre>

You type **exit** to leave tmux.

**tmux Commands**

* You can do many things with tmux like divide your 1 container terminal into multiple terminals all running in the same container.
* The key stroke **Ctrl + b** (Ctrl-b) is used to send command to tux.
* Use **Ctrl-b**, then **?** to see a list of commands. Type **q** to close that list.

**Scrolling text in tmux**

* You will notice that you cannot scroll up to previous text in the window when using tmux.
* To enter 'scroll mode', use **Ctrl-b**  then  **[**
* Then you can use your normal navigation keys to scroll around (eg. Up Arrow or PgDn).
* Press **q** to quit scroll mode.


**Other Examples:**

* **Ctrl-b  + %** &nbsp; (will split the window horizontally into 2 and give you a new terminal)
* **Ctrl-b  +** " &nbsp; (will split the window vertically into 2 and give you a new terminal)
* **Ctrl-b  + arrow-keys** &nbsp; (will move between the different split window)
* Type **exit** will close a tmux window

<br>

<br>

<br>

## 5. Extra Notes

### 5.1 More Details on Docker
* https://docs.docker.com/install/linux/docker-ce/ubuntu
* https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04

### 5.2 Common Docker commands

```
$ docker images         # shows you your availible images
$ docker ps             # shows running containers
$ docker ps -a          # shows all containers (running and not running)
$ docker start -i <container>
$ docker rm <container> # remove a container
$ docker rmi <image>    # remove a image
```


### 5.3 Rename a container (in case you don't like the name)
If you do not specify a name, one is automatically generated.<br>
If you really don't like the name that was automatically generated, you can change it using the docker rename command.
```
$ docker rename CONTAINER NEW_NAME
```

### 5.3 Change your prompt inside your container
When you are **inside** your container, you can change the prompt in your terminal to make it easier to remember what window is your docker window.
When you are inside your container, simply add the following 2 lines to your contianer's  ~/.bashrc file.
<br>
**If you used the supplied dockerfile to create your Images, this is already done.**
<pre>
PS1="\[\e[33m\]dir: \w\n\[\e[1;31m\](docker)$\[\e[00m\] "

printf "\e]2;docker\a"
</pre>

### 5.4 Add a mount to a container that you've already created
 * These instructions are for if you used the docker run command without the -v option, but now you decide you want it.

A container has its own restricted file system space.
Any files you create in that container can only be accessed from within that container.
You might want the container just so you can do Yocto builds on files that reside outside of your container.
In that case, you'll want to 'mount' a directly inside your container.
Note, you can only add a mount when you first [create] the container.
That was done with the 'docker run' command.
So if you didn't do it, you'll have to save what you have as a new 'image' and then make a new container from that.

For example, I want to mount an OUTSIDE directory of /home/renesas/ to the location /home/renesas/ INSIDE my container. Basically so I can get to all my files from inside or outside my container environment.
First I had to make a directory " /home/renesas " inside my container:
```
	[ inside the container ]
	$ sudo mkdir /home/renesas
	$ sudo chown chris:chris /home/renesas
	$ exit
```
You can commit your existing 'container' (that is create a new 'image' from
container's changes) and then run it with your new mounts.
   'docker commit 5a8f89adeead newimagename'

$ docker commit distracted_bohr ubuntu_16.04_chris
$ docker images

Create a new container using that new image
$ docker run -ti -v "/home/renesas/yocto":/home/renesas/yocto ubuntu_16.04_chris /bin/bash

Now start that new container and enter it. Everything should be the same, but now you can see /home/renesas
```
$ docker start dreamy_shannon
$ docker exec -it --user chris dreamy_shannon /bin/bash
```

You can remove your old container now because it's not needed anymore
```
$ docker rm distracted_bohr
```

### 5.5 Manual Steps in Setting Up a Container

These are the steps you would have to do if you did not use the dockerfile to create your image.

**Download a pre-made Ubuntu 16.04 LTS "image"**

Download a Ubuntu 16.04 LTS image from Docker Hub.
You have to specify the tag "xenial" to get the 16.04 version (xenial was the code name for Ubuntu 16.04)

<pre>
$ docker pull ubuntu:xenial
</pre>

**Create a new "container" that is based on an "image"**

You create 'containers' which are running instances of 'images'. They don't change the original image (it's like a clone).
But, if you want to save/transfer that container to another machine, or make another container using a current container as a starting point, you have to first 'commit' that container back to an 'image' file.
Note that many command line options/features are only available when you first create the container. If you missed something, you'll have to recreate the container from scratch again.

**Create a new container**

After you run the 'docker run' command, it will drop you off as user 'root' on the command line so you can set up your environment. At that point you will want to set up a user account (using the **same user name** that you use on your host machine) because you do not want to be doing everything inside your container as root.
Below use **your name** instead of "chris"
Also remember that we want to 'mount' a directory location outside our container to show up inside out container.
For this example, we will create a new directory called 'yocto' in your home directory.
Note that when we use the -v option, the directory inside the container will automatically be created.
The -it instructs Docker to allocate a pseudo-TTY connected to the container's stdin.

<pre>
$ mkdir /home/$USER/yocto
$ docker run -it -v "/home/$USER/yocto":/home/$USER/yocto ubuntu:xenial

	[ inside the container ]
	## Set your user name to be the same as your host machine to match /home/$USER
	root@xxxxxxx:/#  MY_NAME=chris

	## Add yourself as a user
	root@xxxxxxx:/#  useradd -s /bin/bash $MY_NAME
	root@xxxxxxx:/#  passwd $MY_NAME
	Enter new UNIX password:
	Retype new UNIX password:
	passwd: password updated successfully

	## set up your home directory by copying default files
	root@xxxxxxx:/#  mkdir -p /home/$MY_NAME
	root@xxxxxxx:/#  cp -v /etc/skel/.bash* /home/$MY_NAME
	root@xxxxxxx:/#  cp -v /etc/skel/.profile /home/$MY_NAME
	root@xxxxxxx:/#  chown $MY_NAME:$MY_NAME /home/$MY_NAME/*

	## Add sudo, and then add yourself to it
	root@xxxxxxx:/#  apt-get update
	root@xxxxxxx:/#  apt-get install sudo
	root@xxxxxxx:/#  usermod -a -G sudo $MY_NAME

	# That's all we need to do as root since now we have sudo
	root@xxxxxxx:/#  exit
</pre>

NOTE: The "xxxxxxx" will be your container ID. You can use that number to start up this specific container later.


**Start your container running (if it is stopped, doesn't show up in 'docker ps' )**
If you type

<pre>
$ docker ps
</pre>

and nothing shows up, that means no containers are running. If you add "-a" to that command you can see all the containers that you have created by have not started yet.

<pre>
$ docker ps -a
</pre>

NOTE: Docker will automatically make silly names for each container as well as container IDs.
You can either use the Container ID  value or silly name when referencing the container.

<pre>
$ docker start distracted_bohr
</pre>
or
<pre>
$ docker start ff6d1973d9d9
</pre>

Now you should see that your container is 'running'
<pre>
$ docker ps   # this will show you the status of 'running' containers
</pre>

**Enter back into your running "container" as a user**

Your container is running, but you need to enter back into by executing a shell terminal inside of it.
Remember to use your name instead of 'chris'.
You can use the container NAME  or CONTAINER ID
```
$ docker exec -it --user chris distracted_bohr /bin/bash
```

**Configure local for en_US.UTF-8**

By default for the Ubutnu images is that the local is not set,
so everything will be set to "POSIX". Yocto is not going to like that.

<pre>
	[ inside the container ]
	$ locale     # notice that everything is "POSIX"

	# Set local as en_US.UTF-8
	$ sudo apt-get update
	$ sudo apt-get install locales
	$ sudo dpkg-reconfigure locales

		"149" will be "en_US.UTF-8 UTF-8", that's what we want to use.

		Locales to be generated: 149   <<<---- enter "149" -----

		  1. None  2. C.UTF-8  3. en_US.UTF-8
		Default locale for the system environment: 3  <<<--- enter "3"

	$ sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
	$ sudo update-locale LANG=en_US.UTF-8
	$ cat /etc/default/locale


	# NOTE: This this looks like it sets the default to en_US.UTF-8, but
	# in never really worked for me. Every time I ran 'locale', it always
	# kept saying "POSIX", and of course Yocto would not build.
	# So, after doing the steps above, I added a line to my ~/.bashrc
	# so it would automaticlly set LANG each time I logged in, and that
	# worked every time.

	$ echo '' >> ~/.bashrc
	$ echo '# Set locale manually' >> ~/.bashrc
	$ echo 'export LANG=en_US.UTF-8' >> ~/.bashrc
	$ source ~/.bashrc
	$ locale

	# you can leave the conainter at any time.
	$ exit
</pre>

**Change time zone inside container**

The container will get the time and date from the host machine, but the time zone might be different. Therefor set the timezone inside the container to match your host machine using the tzdata.
<pre>
	[ inside the container ]
	$ sudo apt-get install tzdata
	$ sudo dpkg-reconfigure tzdata
	$ ls -la /etc/localtime
	lrwxr-xr-x  1 root  wheel  36 Aug 24 13:17 /etc/localtime -> /usr/share/zoneinfo/America/New_York
</pre>

**Add 'tumx' so things like menuconfig will display correctly**

When you inside a container, the "terminal" you are executing commands is not a standard terminal and some things will not display correctly. However, you can run 'tumx' which emulates a standard terminal and then things (like menuconfig) will all look correct inside your container.

<pre>
	#Install tmux
	[ inside the container ]
	$ sudo apt-get install tmux
</pre>

Run this each time you enter the container (before you start to do any Yocto work)
<pre>
	$ tmux
</pre>

**Suggestions software packages to add inside your container**

Here are some common packages that are useful inside your container even though you will only be using it for Yocto builds.

<pre>
$ sudo apt-get update
$ sudo apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat libsdl1.2-dev xterm cpio python python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping libssl-dev
</pre>

For menuconfig, you need the ncurser package:

<pre>
$ sudo apt-get install libncurses5-dev libncursesw5-dev
</pre>

From the RZ/G2 VLP64 build instructions, these packages are required:

<pre>
$ sudo apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib \
build-essential chrpath socat cpio python python3 python3-pip python3-pexpect \
xz-utils debianutils iputils-ping libsdl1.2-dev xterm p7zip-full
</pre>

