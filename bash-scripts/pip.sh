#! /bin/bash
COLUMNS=1
select action in   "${tgreen}List${treset}" "${tblue}Init${treset}" "${tgreen}Activate${treset}" "${tmagenta}Deactivate${treset}" "${tblue}Install Package${treset}" "${tblue}Install all${treset}" "${tmagenta}Uninstall${treset}"  "${tmagenta}Exit${treset}"; do
  case $action in
    "${tgreen}List${treset}")
      python3 -m pip freeze
      ;;
    "${tblue}Init${treset}")
      current_dir=$(pwd)
      python3 -m venv venv
      source venv/bin/activate
      python3 -m pip install --upgrade pip
      ;;
    "${tgreen}Activate${treset}")
      source venv/bin/activate
      ;;
    "${tmagenta}Deactivate${treset}")
      deactivate
      ;;
    "${tblue}Install Package${treset}")
      read -p "Enter the package name: " package_name
      python3 -m pip install $package_name
      python3 -m pip freeze > requirements.txt
      ;;
    "${tblue}Install all${treset}")
      python3 -m pip install -r requirements.txt
      ;;
    "${tmagenta}Uninstall${treset}")
      read -p "Enter the package name: " package_name
      python3 -m pip uninstall $package_name
      python3 -m pip freeze > requirements.txt
      ;;
    "${tmagenta}Exit${treset}")
      exit 0
      ;;
    *)
      echo "Invalid option"
      exit 0
      ;;
  esac
done

read -p "Enter the package name: " package_name

