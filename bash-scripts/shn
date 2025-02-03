#!/bin/bash


# Check for running background jobs
if jobs | grep -q '[0-9]'; then
    echo "${blue}There are background jobs running:${reset}"
    jobs
    echo "${tgreen}type kill %1 to kill the job${treset}"
    #press enter to continue
    return
fi

# Check for active screen sessions
if screen -ls | grep -q '\.server'; then
    echo "${tmagenta}There are active screen sessions:${treset}"
    screen -ls
    echo "${tmagenta}type kill_server [session_name] to kill the session${treset}"
    return
fi

# Check if docker containers are running
if docker ps | grep -q '[0-9]'; then
    echo "${tmagenta}There are active docker containers:${treset}"
    docker ps
    echo "${tmagenta}type docker_stop_all to stop all containers${treset}"
    return
fi

# wait for user input
read -p "No background jobs or active screen sessions found. Shut down? [y/n] " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo shutdown -h now
else
    echo "${tgreen}Shutdown aborted${treset}"
fi
