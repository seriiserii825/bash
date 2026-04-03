source "$(dirname "${BASH_SOURCE[0]}")/modules/getProjectType.sh"
source "$(dirname "${BASH_SOURCE[0]}")/modules/vueHandler.sh"

function portsHandler(){
  project_type=$(getProjectType)
  case $project_type in
    "vue")
      vueHandler
      ;;
    "react")
      echo "react"
      ;;
    "nuxt")
      echo "nuxt"
      ;;
    "next")
      echo "next"
      ;;
    "wordpress")
      echo "wordpress"
      ;;
    *)
      echo "Unknown project type: $project_type"
      exit 1
      ;;
  esac
}

portsHandler
