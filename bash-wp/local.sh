#! /bin/bash 

ids=($(cat /home/$USER/.config/Local/sites.json | jq -r '.[].id'))
domain=($(cat /home/$USER/.config/Local/sites.json | jq -r '.[].domain'));

# echo "domain: ${domain[@]}";
length=${#ids[@]};
for (( j=0; j<length; j++ )); 
  do printf "${domain[$j]} ${ids[$j]}\n"
  # echo "domain: ${domain[$j]}";
  # do printf "\n%s:\nbash /home/$USER/.config/Local/ssh-entry/%s.sh;\n" "${domain[$j]}" "${ids[$j]}"; 
done;

