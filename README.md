# Alien scripts
This repository consists in two series of bash scripts linux and Mac OSX compatible that can be used to programmatically operate repetitive actions on the Alien GRID interface.

## Setup repository
```bash
cd chosenDir
git clone https://github.com/gabrielefronze/Alien-Scripts
```

## Versions
The repository is composed of two versions of 3 scripts:
- **sequential version** identified as scriptname.sh, this version is a blocking implementation. The script, looping over the targets, waits for an handshacke after every sent command. The script execution finishes only when all the communication has received a confirmation.
- **non-blocking version** indentified as scriptname_par.sh provides a non blocking implementation of the same commands. Here each command is launched in background on a different thread (maximum number of threads is limited based on hardware specs). Actually the handshacke procedure happens in this case too, but since the processes are launched in background, the script end the execution when all the requests have been sent, without waiting for feedback.

## Script names
- **kill and kill_par** is used to kill all user's jobs currently running on the GRID.
- **resubmit resubmit_all** is used to resubmit all user's jobs of which the state is ESP (Error SPlitting), EI (Error Inputbox) or EXPIRED (Expired status). Other errors can be handled by the script by adding some lines of the following type (around line 62):
  ```bash
  
  [...]
  cat $FILEPATH | grep " error_or_status_ID" | grep -o '[0-9]\{9\}' >> failedmasterjobs.txt
  [...]
  
  ```
- **kill_done and kill_done_par** is used to clean the job management page by removing entries related to completed jobs (DONE status).

## Compatibility
All the script have been tested on Mac OSX and linux (Ubuntu 14) systems and no bug has been detected.

## Bash export
The scripts of this repository can be exported as usual via editing the .bash_profile or .bashrc files.
  ```bash
  alias alien_kill_all='source /path_to_scripts/kill_par.sh'
  alias alien_resubmit_all='source /path_to_scripts/resubmit_par.sh'
  alias alien_kill_done='source /path_to_scripts/kill_done_par.sh'
  ```
  
** CAVEAT: ** If one manages to run two istances of this **non-blocking** scripts in a while (read: before the first command queue has been emptied) the second script will hang on until all the commands have been perfomed correctly, hence turning to a **blocking** behavior. This is kindly due to Alien queue handling policies and is not really related to the scripts themselves. 
