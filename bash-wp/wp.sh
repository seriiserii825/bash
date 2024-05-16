#! /bin/bash
args=("$@")

if [ ! -f "front-page.php" ]
  then
  echo "${terror}front-page.php not found, it's not a wordpress template${treset}"
  exit 1
fi

if [ ! -d "components" ]
  then
    mkdir -p "components"
fi

scss_layout_path='src/scss/layouts/default.scss'
if [ ! -f "$scss_layout_path" ]
  then
    touch "$scss_layout_path"
  cat <<TEST >> "$scss_layout_path"
.home {
  &__title{}
}
TEST
fi

php_component_layout="template-parts/layouts/php-component.php"
if [ ! -f "$php_component_layout" ]
  then
    touch "$php_component_layout"
  cat <<TEST >> "$php_component_layout"
<?php  function defaultComponent(){ ?>

<?php } ?>
TEST
fi

vue_layout_path='template-parts/layouts/default.vue'
if [ ! -f "$vue_layout_path" ]
  then
    touch "$vue_layout_path"
  cat <<TEST >> "$vue_layout_path"
  <script lang="ts" setup>

  </script>
  <template>
  <div class="vue"></div>
  </template>
TEST
fi

defaul_php_layout="template-parts/layouts/default.php"
if [ ! -f "$defaul_php_layout" ]
  then
    touch "$defaul_php_layout"
  cat <<TEST >> "$defaul_php_layout"
    <?php
    $home = get_field('home');
    $title = $home['title'];
    ?>
<div class="home">
</div>
TEST
fi

js_layout_path='template-parts/layouts/js-layout.ts'
if [ ! -f "$js_layout_path" ]
  then
    touch "$js_layout_path"
  cat <<TEST >> "$js_layout_path"
  export default function jsLayout() {}
TEST
  exit 0
fi

interface_layout_path='template-parts/layouts/default-interface.ts'
if [ ! -f "$interface_layout_path" ]
  then
    touch "$interface_layout_path"
  cat <<TEST >> "$interface_layout_path"
  export interface IDefault {}
TEST
fi

hook_layout_path='template-parts/layouts/default-hook.ts'
if [ ! -f "$hook_layout_path" ]
  then
    touch "$hook_layout_path"
  cat <<TEST >> "$hook_layout_path"
export const useDefault = () => {
};
TEST
fi

pinia_layout_path='template-parts/layouts/default-pinia.ts'
if [ ! -f "$pinia_layout_path" ]
  then
    touch "$pinia_layout_path"
  cat <<TEST >> "$pinia_layout_path"
import { ref } from "vue";
import { defineStore } from "pinia";
export const useDefaultStore = defineStore("default", () => {
  return {
  };
});
TEST
fi


function scssCreate(){
  if [ ! $# -gt 0 -o ! $# -eq 2 ]; then
      read -p "${tgreen}Give directory name, the same as page name, example 'home': ${treset}" dir_name
      read -p "${tgreen}Give file name , example 'features': ${treset}" file_name
  else 
      dir_name=$1
      file_name=$2
  fi

  # create scss directory
  mkdir -p "src/scss/blocks/$dir_name"
  # create scss file
  scss_file_path="src/scss/blocks/$dir_name/$file_name.scss"
  touch "$scss_file_path"
  # copy layout to file
  cat $scss_layout_path > "$scss_file_path"
  # replace layout name
  sed -i -e "s/home/$file_name/g" "$scss_file_path" 

  # import scss file to my.scss
  echo "@import \"blocks/$dir_name"/"$file_name\";" >> src/scss/my.scss

  echo "${tgreen}$scss_file_path was created${treset}";
}


function phpCreate(){
  read -p "${tgreen}Give directory name, the same as page name, example 'home': ${treset}" dir_name
  read -p "${tgreen}Give file name , example 'features': ${treset}" file_name

  wp_dir_path="template-parts/$dir_name"
  mkdir -p  "$wp_dir_path"

  wp_file_path="$wp_dir_path/$file_name.php"
  wp_file_path_without_extension="$wp_dir_path/$file_name"
  touch "$wp_file_path"

  # include file to front-page
  sed -i -e "0,/get_footer/s#.*get_footer.*#<?php echo get_template_part('$wp_file_path_without_extension');?>\n&#" front-page.php
  # copy layout to file
  cat $defaul_php_layout > "$wp_file_path"
  # replace layout name
  sed -i -e "s/home/$file_name/g" "$wp_file_path" 

  # replace acf field name and variable if file name has '-'
  if [[ $file_name =~ '-' ]];
  then
    # echo $file_name |  sed -r 's/-/_/';
    acf_field=$(sed "s/-/_/g" <<< $file_name);
    sed -i -e "s/get_field('$file_name')/get_field('$acf_field')/" $wp_file_path 
    sed -i -e "s/\$$file_name/\$$acf_field/" $wp_file_path 
  fi

  echo "${tgreen}$wp_file_path was created${treset}";

  scssCreate $dir_name $file_name
}

function phpsCreate(){
  read -p "${tgreen}Give directory name, the same as page name, example 'home': ${treset}" dir_name
  read -p "${tgreen}Give file name , example 'features': ${treset}" file_name

  wp_dir_path="template-parts/$dir_name"
  mkdir -p  "$wp_dir_path"

  wp_file_path="$wp_dir_path/$file_name.php"
  wp_file_path_without_extension="$wp_dir_path/$file_name"
  touch "$wp_file_path"

  # include file to front-page
  sed -i -e "0,/get_footer/s#.*get_footer.*#<?php echo get_template_part('$wp_file_path_without_extension');?>\n&#" front-page.php
  # copy layout to file
  cat $defaul_php_layout > "$wp_file_path"
  # replace layout name
  sed -i -e "s/home/$file_name/g" "$wp_file_path" 

  # replace acf field name and variable if file name has '-'
  if [[ $file_name =~ '-' ]];
  then
    # echo $file_name |  sed -r 's/-/_/';
    acf_field=$(sed "s/-/_/g" <<< $file_name);
    sed -i -e "s/get_field('$file_name')/get_field('$acf_field')/" $wp_file_path 
    sed -i -e "s/\$$file_name/\$$acf_field/" $wp_file_path 
  fi

  echo "${tgreen}$wp_file_path was created${treset}";
}

function phpComponentCreate(){
  read -p "${tgreen}Give file name , example 'featuresComponent': ${treset}" file_name

  wp_file_path="components/$file_name.php"
  touch "$wp_file_path"
  cat $php_component_layout > "$wp_file_path"
  sed -i -e "s/defaultComponent/$file_name/g" "$wp_file_path" 
  echo "${tgreen}$wp_file_path was created${treset}";
}

function phpPageCreate(){
  read -p "${tgreen}Give file name , example 'services' for 'page-services': ${treset}" file_name

  wp_file_path="page-$file_name.php"

  touch "$wp_file_path"

  cat "front-page.php" > "$wp_file_path"

  echo "${tgreen}$wp_file_path was created${treset}";
}

function jsCreate(){
  read -p "${tgreen}Give directory name, example 'popups': ${treset}" dir_name
  read -p "${tgreen}Give file name as function name , example 'homePopup': ${treset}" file_name

  mkdir -p  "src/js/modules/$dir_name"
  touch  "src/js/modules/$dir_name"/"$file_name.ts"

  file_path="src/js/modules/$dir_name/$file_name.ts"
  cat "$js_layout_path" > $file_path 
  sed -i -e "s/jsLayout/$file_name/g" "$file_path" 

  echo "${tgreen}$file_path was created${treset}";
}

function vueCreate(){
  read -p "${tgreen}Give directory name, example 'popups': ${treset}" dir_name
  read -p "${tgreen}Give file name as component name, example 'HomePopup': ${treset}" file_name
  file_path="src/vue/components/$dir_name/$file_name.vue"
  mkdir -p "src/vue/components/$dir_name" 
  touch  "src/vue/components/$dir_name"/"$file_name.vue"
  cat $vue_layout_path > $file_path
  sed -i -e "s/vue/$file_name/g" $file_path 
  sed -i -E 's/([a-z])([A-Z])/\1-\L\2/g' $file_path
  sed -i -e 's/class="\([^"]*\)"/class="\L\1"/g' $file_path
  echo "${tgreen}$file_path was created${treset}";
}

function tsCreate(){
  read -p "${tgreen}Give directory name, example 'popups': ${treset}" dir_name
  read -p "${tgreen}Give file name as interface name, example 'IHomePopup': ${treset}" file_name

  mkdir -p  "src/vue/interfaces/$dir_name"
  touch  "src/vue/interfaces/$dir_name"/"$file_name.ts"
  file_path="src/vue/interfaces/$dir_name/$file_name.ts"
  cat "$interface_layout_path" > $file_path 
  sed -i -e "s/IDefault/$file_name/g" "$file_path" 

  echo "$file_path was created";
}

function phpIcon(){
  read -p "${tgreen}Give file name, example 'icon-phone': ${treset}" file_name

  file_path="template-parts/icons/$file_name.php"
  mkdir -p  "template-parts/icons"

  touch "$file_path"

  echo "$file_path was created";
}

function hookCreate(){
  read -p "${tgreen}Give file name as function name, example 'useDefaultHook': ${treset}" file_name

  file_path="src/vue/hooks/$file_name.ts"

  cat $hook_layout_path > $file_path 

  sed -i -e "s/useDefault/$file_name/g" "$file_path" 

  echo "$file_path was created";
}

function piniaCreate(){
  read -p "${tgreen}Give store name with lower case, example 'filter': ${treset}" store_name
  read -p "${tgreen}Give function name with camelCase, example 'usePiniaStore': ${treset}" store_func
  if [ ! -d "src/vue/store" ]; then
    mkdir -p "src/vue/store"
  fi
  touch  "src/vue/store/$store_name-store.ts"
  file_path="src/vue/store/$store_name-store.ts"
  cat "$pinia_layout_path" > $file_path 
  sed -i -e "s/default/$store_name/g" "$file_path" 
  sed -i -e "s/useDefaultStore/$store_func/g" "$file_path" 
  echo "$file_path was created";
}


api_layout_path='template-parts/layouts/api-layout.ts'


if [ ! -f "$api_layout_path" ]
  then
    touch "$api_layout_path"
  cat <<TEST >> "$api_layout_path"
import { axiosInstance } from "../utils/axios-instances";
export async function fetchApi(url: string) {
  const data = await axiosInstance.post(url, {
    error_alert: "fetchApi error",
  });
  const result = data.data.data;
  return { data: result };
}
TEST
fi

function createApi(){
  if [ ! $# -gt 0 -o ! $# -eq 2 ]; then
      read -p "${tgreen}Give directory name, example 'home': ${treset}" dir_name
      read -p "${tgreen}Give file name , example 'featuresApi': ${treset}" file_name
  else 
    exit 1;
  fi

  mkdir -p "src/vue/api/$dir_name"
  dir_path="src/vue/api/$dir_name"
  file_path="$dir_path/$file_name.ts"
  touch "$file_path"
  cat $api_layout_path > "$file_path"
  sed -i -e "s/fetchApi/$file_name/g" "$file_path" 
  echo "${tgreen}$file_path was created${treset}";
}


defaultOption="php" # Set the default option here
read -p "${tblue}Select an option: 
  php
  phps
  phpc(component)
  phpp(page)
  phpi(icon)
  hook
  scss
  js
  vue
  ts
  api
  pinia
  by default is php: ${treset}" choice
if [ -z "$choice" ]; then
  choice=$defaultOption
  echo "${tblue}Default option selected: $choice ${treset}"
fi

case $choice in
  php)
    phpCreate
    ;;
  phps)
    phpsCreate
    ;;
  phpc)
    phpComponentCreate
    ;;
  phpp)
    phpPageCreate
    ;;
  phpi)
    phpIcon
    ;;
  scss)
    scssCreate
    ;;
  js)
    jsCreate 
    ;;
  vue)
    vueCreate 
    ;;
  ts)
    tsCreate
    ;;
  hook)
    hookCreate
    ;;
  api)
    createApi
    ;;
  pinia)
    piniaCreate
    ;;
  *)
    echo "${tred}${twhiteb}Invalid option selected${treset}"
    ;;
esac

