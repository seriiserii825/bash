#! /bin/bash
args=("$@")

api_layout_path="src/layouts/apiLayout.ts"
store_layout_path="src/layouts/storeLayout.ts"
inteface_layout_path="src/layouts/intefaceLayout.ts"
component_layout_path="src/layouts/componentLayout.vue"
scss_layout_path="src/layouts/scss.vue"
enum_layout_path="src/layouts/enumLayout.vue"
view_layout_path="src/layouts/viewLayout.vue"

if [ ! -d "src/layouts" ]
  then
    mkdir -p "src/layouts"
fi

function checkLayouts(){
  if [ ! -f "src/App.vue" ]
    then
    echo "${tred}src/App.vue not found${treset}"
    exit 1
  fi
}
checkLayouts

function apiCreate(){
  read -p "${tgreen}Give file name , example 'authApi': ${treset}" file_name
  mkdir -p "src/api"
  api_file_path="src/api/$file_name.ts"
  if [ -f "$api_file_path" ]
    then
      echo "${tred}$api_file_path already exists${treset}"
      exit 1
  fi
  touch "$api_file_path"
  if [ ! -f "$api_layout_path" ]
    then
      createApiLayout
      cat "$api_layout_path" > "$api_file_path"
      sed -i -e "s/apiLayout/$file_name/g" "$api_file_path" 

      echo "${tgreen}$api_file_path was created${treset}";
    else
      cat "$api_layout_path" > "$api_file_path"
      sed -i -e "s/apiLayout/$file_name/g" "$api_file_path" 

      echo "${tgreen}$api_file_path was created${treset}";
  fi
}

function createApiLayout(){
  touch "$api_layout_path"
  cat <<TEST >> "$api_layout_path"
    import {axiosInstance} from "../axios/axios-instance";
    export async function apiLayout() {
        const data = await axiosInstance.get('/login', {
            error_alert: "apiLayout"
        });
        return {data: data};
    }
TEST
}


function createStoreLayout(){
  touch "$store_layout_path"
  cat <<TEST >> "$store_layout_path"
  import { ref } from "vue";
  import { defineStore } from "pinia";

  export const useDefaultStore = defineStore("default", () => {


    return {
    };
  });
TEST
}

function storeLayoutToFile(){
  file_path=$1
  store_name=$2
  store_func=$3
  cat "$store_layout_path" > $file_path 
  sed -i -e "s/default/$store_name/g" "$file_path" 
  sed -i -e "s/useDefaultStore/$store_func/g" "$file_path" 
  echo "$file_path was created";
  exit 0
}

function createStore(){
  read -p "${tgreen}Give store name with lower case, example 'filter': ${treset}" store_name
  read -p "${tgreen}Give function name with camelCase, example 'usePiniaStore': ${treset}" store_func

  if [ ! -d "src/stores" ]
    then
      mkdir -p "src/stores"
  fi

  file_path="src/stores/$store_name-store.ts"
  if [ -f "$file_path" ]
    then
      echo "${tred}$file_path already exists${treset}"
      exit 1
  fi
  touch  $file_path
  
  if [ ! -f "$store_layout_path" ]
    then
      createStoreLayout 
      storeLayoutToFile $file_path $store_name $store_func
    else
      storeLayoutToFile $file_path $store_name $store_func
  fi
}

function interfaceLayoutToFile(){
  dir_name=$1
  file_name=$2
  mkdir -p  "src/interfaces/$dir_name"
  file_path="src/interfaces/$dir_name/$file_name.ts"
  if [ -f "$file_path" ]
    then
      echo "${tred}$file_path already exists${treset}"
      exit 1
  fi
  touch  $file_path
  cat "$inteface_layout_path" > $file_path 
  sed -i -e "s/IDefault/$file_name/g" "$file_path" 
  echo "$file_path was created";
  exit 0
}

function createInterface(){
  read -p "${tgreen}Give directory name, example 'popups': ${treset}" dir_name
  read -p "${tgreen}Give file name as interface name, example 'IHomePopup': ${treset}" file_name

  if [ ! -f "$inteface_layout_path" ]
    then
      createIntefaceLayout 
      interfaceLayoutToFile $dir_name $file_name
    else
      interfaceLayoutToFile $dir_name $file_name
  fi
}

function createIntefaceLayout(){
  touch "$inteface_layout_path"
  cat <<TEST >> "$inteface_layout_path"
  export interface IDefault {

  }
TEST
}

function createHook(){
    read -p "${tgreen}Give hook name, example 'useLocalStorage': ${treset}" hook_name
    mkdir -p "src/hooks"
    file_path="src/hooks/$hook_name.ts"
    if [ -f "$file_path" ]
      then
        echo "${tred}$file_path already exists${treset}"
        exit 1
    fi
    touch "$file_path"
    cat <<TEST >> "$file_path"
    export default function $hook_name() {
    }
TEST

  echo "$file_path was created";
}

function createComponentLayout(){
  touch "$component_layout_path"
  cat <<TEST >> "$component_layout_path"
<script setup lang="ts">
</script>

<template>
  <div class="default">

  </div>
</template>
TEST
}

function createViewLayout(){
  touch "$view_layout_path"
  cat <<TEST >> "$view_layout_path"
<script setup lang="ts">
</script>

<template>
  <div class="default-view">

  </div>
</template>
TEST
}

function createView(){
  if [ ! -f "$view_layout_path" ]
    then
      createViewLayout
  fi
  read -p "${tgreen}Give view name, example 'Home': ${treset}" cmp_name
  file_path="src/views/${cmp_name}View.vue"
  if [ -f "$file_path" ]
    then
      echo "${tred}$file_path already exists${treset}"
      exit 1
  fi
  touch "$file_path"
  cp "$view_layout_path" "$file_path"
  sed -i -e "s/default/$cmp_name/g" "$file_path"
  sed -i -E 's/([a-z])([A-Z])/\1-\L\2/g' $file_path
  sed -i -e 's/class="\([^"]*\)"/class="\L\1"/g' $file_path
  echo "${tgreen}src/views/${cmp_name}View.vue was created${treset}"
}

function createEnumLayout(){
  touch "$enum_layout_path"
  cat <<TEST >> "$enum_layout_path"
export enum E_Default {

}
TEST
}

function createEnum(){
      if [ ! -f "$enum_layout_path" ]
        then
          createEnumLayout
      fi
      read -p "${tgreen}Give enum name, example 'Filter' will be E_Filter: ${treset}" cmp_name
      mkdir -p "src/enum"
      file_path="src/enum/E_$cmp_name.vue"
      if [ -f "$file_path" ]
        then
          echo "${tred}$file_path already exists${treset}"
          exit 1
      fi
      touch "$file_path"
      cp "$enum_layout_path" "$file_path"
      sed -i -e "s/Default/$cmp_name/g" "$file_path"
      sed -i -E 's/([a-z])([A-Z])/\1-\L\2/g' $file_path
      sed -i -e 's/class="\([^"]*\)"/class="\L\1"/g' $file_path
      echo "${tgreen}src/enum/E_${cmp_name}.vue was created${treset}"
}

function createScssLayout(){
  touch "$scss_layout_path"
  cat <<TEST >> "$scss_layout_path"
.home {
  &__title{}
}
TEST
}

function scssCreate(){
  if [ ! -f "$scss_layout_path" ]
    then
      createScssLayout
  fi
  read -p "${tgreen}Give directory name, the same as page name, example 'home': ${treset}" dir_name
  read -p "${tgreen}Give file name , example 'features': ${treset}" file_name

  # create scss directory
  mkdir -p "src/scss/blocks/$dir_name"
  # create scss file
  scss_file_path="src/scss/blocks/$dir_name/$file_name.scss"
  if [ -f "$scss_file_path" ]
    then
      echo "${tred}$scss_file_path already exists${treset}"
      exit 1
  fi
  touch "$scss_file_path"
  # copy layout to file
  cat $scss_layout_path > "$scss_file_path"
  # replace layout name
  sed -i -e "s/home/$file_name/g" "$scss_file_path" 

  # import scss file to my.scss
  echo "@import \"blocks/$dir_name"/"$file_name\";" >> src/scss/my.scss

  echo "${tgreen}$scss_file_path was created${treset}";
}



view="${tblue}view${treset}";
enum="${tgreen}enum${treset}";
api="${tgreen}api${treset}";
cmp="${tyellow}cmp${treset}";
store="${tred}store${treset}";
interface="${tcyan}interface${treset}";
hook="${tyellow}hook${treset}";
scss="${tyellow}scss${treset}";

COLUMNS=1
select action in $view $enum $api $cmp $store $interface $hook $scss; do
  case $action in 
    $view)
      createView
      exit 0
      ;;
    $enum)
      createEnum
      exit 0
      ;;
    $api)
      apiCreate
      exit 0
      ;;
    $cmp)
      if [ ! -f "$component_layout_path" ]
        then
          createComponentLayout
      fi
      read -p "${tgreen}Give component directory, example 'popups': ${treset}" cmp_dir
      read -p "${tgreen}Give component name, example 'Home': ${treset}" cmp_name
      mkdir -p "src/components/$cmp_dir"
      file_path="src/components/$cmp_dir/$cmp_name.vue"
      if [ -f "$file_path" ]
        then
          echo "${tred}$file_path already exists${treset}"
          exit 1
      fi
      touch "$file_path"
      cp "$component_layout_path" "$file_path"
      sed -i -e "s/default/$cmp_name/g" "$file_path"
      sed -i -E 's/([a-z])([A-Z])/\1-\L\2/g' $file_path
      sed -i -e 's/class="\([^"]*\)"/class="\L\1"/g' $file_path
      echo "${tgreen}src/components/$cmp_dir/$cmp_name.vue was created${treset}"
      exit 0
      ;;
    $store)
      createStore
      exit 0
      ;;
    $interface)
      createInterface
      exit 0
      ;;
    $hook)
      createHook
      exit 0
      ;;
    $scss)
      scssCreate
      exit 0
      ;;
    *)
      echo "${tred}Invalid option selected${treset}"
      ;;
  esac
done
