# Ansible Dynamic Playbook

Attempt at having some playbook patterns we need for our deployments including:
* **Dynamic playbook roles** - ability to dynamically include different roles based on variables
* **Environment vars** - using environment vars (e.g. from a Team city job) to control aspects of execution
* **Docker Container** - how to run ansible w/in a docker container based on rhel8x image

| Pattern            | Playbook/File |
| ------------------ | ------------- |
| Dynamic Playbook   | dynamicPlaybook.yaml (2,3) |
| Environment vars   | envVarsPlaybook.yaml       |
| Docker container   | Dockerfile                 |

## Dynamic playbook scenario
Currently when our applications deploy we will need to run entirely different roles based
on various configuration options.

Options:
* **Option 1** - use basic if statements in playbook (e.g. refer to dynamicPlaybook.yaml)
* **Option 2** - create dictionary of supported ansible roles to global values (e.g. refer to dynamicPlaybook2.yaml)
* **Option 3** - hard code array of values to run (e.g. assumes generated outside ansible process - dynamicPlaybook3.yaml)

## Environment variables
A possible scenario we need is to have different environment variables control flow logic and terraform modules.

Currently we have a bash.sh file that controls execution using various environment variables for different actions to perform.

An alternative option is to remove the bash file and replace with ansible playbook/roles for the different actions.

The envVarsPlaybook.yaml demonstrates various options using that pattern.


## Tools Utilized
The project utilizes
* **Python3** - Python module to invoke ansible
* **Ansbile** - [Ansible automation](https://docs.ansible.com/ansible/2.9/index.html)

## Project Structure
The project utilizes this structure

```
├── project                 (ansible top level project folder)
|     ├── group_vars
|           all.yaml        (global vars)
|     ├── roles             (ansible roles)
|       ├── Bods4200         (ansible role)
|           ├── defaults
|           ├── tasks
|               main.yaml
|       ├── Bods4300         (ansible role)
|           ├── defaults
|           ├── tasks
|               main.yaml
|       ├── Ora19c          (ansible role)
|           ├── defaults
|           ├── tasks
|               main.yaml
|       .... (more roles)    
|     ├── dynamicPlaybook.yaml     (sample playbook invoked)
|     ├── dynamicPlaybook2.yaml     (sample playbook invoked)
|     ├── envVarsPlaybook.yaml     (sample playbook invoked)
├── Dockerfile                     (rhel8 docker file example)
├── DockerfileRhel7                (rhel7 docker file example)
├── requirements.txt               (python required modules)
```


## Python Setup
The project assumes python 3.9. This project was also minimally tested using python 2.x by running some playbooks w/in the rhel7 docker image. 

Our current requirement is for rhel8.x which provides python3.8 OOTB. I only used 3.9 since I already had this installed on my machine.

Additionally this assumes using venv for virtual environments with all requirements installed w/in the virtual environment.

```bash
# install python 3.9
brew install python@3.9

# verify version is install
python3 --version

# location
which python3
# /opt/homebrew/bin/python3

### create venv to install packages
# Create directory for venvs (don't do it inside this directory)
mkdir python_virtualenvs
cd python_virtualenvs

# create venv for all our stuff (ansibledynamicplaybook)
python3 -m venv ansibledynamicplaybook

# activate this env
# source ansibledynamicplaybook/bin/activate
source python_virtualenvs/ansibledynamicplaybook/bin/activate

# or if running from other directory (ansibledynamicplaybook)
source ../python_virtualenvs/ansibledynamicplaybook/bin/activate

# verify python location
which python3
# xxxxxxx/python_virtualenvs/ansibledynamicplaybook/bin/python3
```

To install all required python modules (e.g. ansible version, ansible runner, etc.)

```bash
# before running must install specific python modules
pip install -r requirements.txt
```

## Command line execution
To run this locally you need to invoke the playbook directly on the command line.

Since there are numerous patterns defined in different playbooks some samples are listed below.

```bash
## run basic 
ansible-playbook -i hosts project/dynamicPlaybook.yaml

## run with global variables overidden demonstrating different roles to execute
ansible-playbook -i hosts project/dynamicPlaybook.yaml --extra-vars "default_os_ver=rhel82 default_db_ver=oracle20c default_bods_ver=4300"

## run with global variables overidden demonstrating different roles to execute
ansible-playbook -i hosts project/dynamicPlaybook2.yaml --extra-vars "default_os_ver=rhel82 default_db_ver=oracle20c default_bods_ver=4300"

## run with array based global variables overidden demonstrating different roles to execute
## note the usage of json for the extra-vars
ansible-playbook -i hosts project/dynamicPlaybook3.yaml --extra-vars '{"roles_to_run": [rhel8x,Ora20c,Bods4300]}'

## run with array based global variables overidden demonstrating different roles to execute (ERROR scenario w/invalid version)
ansible-playbook -i hosts project/dynamicPlaybook2.yaml --extra-vars "default_os_ver=rhel99 default_db_ver=oracle20c default_bods_ver=4300"

## run envVarsPlaybook
ansible-playbook -i hosts project/envVarsPlaybook.yaml

## run envVarsPlaybook (with args) (ansible requires bools w/in extra vars to be defined this way)
ansible-playbook -i hosts project/envVarsPlaybook.yaml -e '{env_vars: [{stackPrep: True}, {rdsStack: False}]}'

```

Alternative invocation method using the minimal_ansible_playbook runner python script. This is just here to ensure it'll work

```bash
# invoke the playbook using the bash shell file
./applicationStart.sh

# check the return code from last script run (0 is OK 1 is failed)
echo $?
```

## Docker image execution
An alternative to installing ansible/python locally is using a docker container to run the playbooks.

This assumes you have docker desktop already installed on your localmachine.

There is a sample Dockerfile to build the container and include ansible via pip3.

### rhel8 version commands (e.g. Dockerfile)

```bash
# build the image and tag as "ansible_local:latest"
docker build -t ansible_local:latest .

# run the image in interactive mode (and bind the current working directory to container's app directory)
docker run -it --mount type=bind,source="$(pwd)",target=/app  ansible_local

# w/in the container at the current prompt 
# [root@a51c5ee2fcc1 /]# 
ansible --version
 
# nav into /app directory we created w/in the container
cd /app

# run ansible-playbook command
ansible-playbook -i hosts project/envVarsPlaybook.yaml

```

### rhel7 version commands (e.g. DockerfileRhel7)

```bash
# build the image and tag as "ansible_local:latest"
docker build --file DockerfileRhel7 -t ansible7x_local:latest . --platform linux/amd64

# run the image in interactive mode (and bind the current working directory to container's app directory)
# also must start bash
docker run -it --mount type=bind,source="$(pwd)",target=/app  ansible7x_local /bin/bash

# w/in the container at the current prompt 
# [root@a51c5ee2fcc1 /]# 
ansible --version
 
# nav into /app directory we created w/in the container
cd /app

# run ansible-playbook command (within the container)
ansible-playbook -i hosts project/envVarsPlaybook.yaml

```



## Open Issues
The following are open issues/items 
* **Python2.x** - unclear if this solution fully works for older python versions. Minor testing was performed on python2.x using docker image
* **Unit Testing** - it would be nice to unit test this playbook since there's logic in there but doesn't appear easy way to do so
