#!/bin/bash

COLUMNS=1
function migrate(){
  select action in Creat_migration Create_migration_with_table Run_migration Create_seeder Seed Create_factory Fresh_seed Rollback Rollback_step Reset Clear; do
    case $action in
      Creat_migration)
        read -p "Migration name like 'create_flights_table': " migration_name
        docker-compose exec php-fpm php artisan make:migration $migration_name
        ;;
      Creat_migration_with_table)
        read -p "Migration name like 'create_flights_table': " migration_name
        read -p "Table name like 'flights': " table_name
        docker-compose exec php-fpm php artisan make:migration $migration_name --table=$table_name
        ;;
      Run_migration)
        docker-compose exec php-fpm php artisan migrate
        ;;
      Create_seeder)
        read -p "Seeder name like 'FlightsTableSeeder': " seeder_name
        docker-compose exec php-fpm php artisan make:seeder $seeder_name
        ;;
      Seed)
        docker-compose exec php-fpm php artisan db:seed
        exit 0
        ;;
      Create_factory)
        read -p "Factory name like 'FlightsFactory': " factory_name
        docker-compose exec php-fpm php artisan make:factory $factory_name
        ;;
      Fresh_seed)
        docker-compose exec php-fpm php artisan migrate:fresh --seed
        ;;
      Rollback)
        docker-compose exec php-fpm php artisan migrate:rollback
        ;;
      Rollback_step)
        read -p "How many steps you want to rollback: " step
        docker-compose exec php-fpm php artisan migrate:rollback --step=$step
        ;;
      Reset)
        docker-compose exec php-fpm php artisan migrate:reset
        ;;
      Clear)
        docker-compose exec php-fpm php artisan view:clear && docker-compose exec php-fpm php artisan cache:clear && docker-compose exec php-fpm php artisan config:cache && docker-compose exec php-fpm php artisan route:clear
        exit 0
        ;;
      *)
        echo "ERROR! Please select between 1..3"
        ;;
    esac
  done
}

COLUMNS=1
function model(){
  select action in Create_model Model_migration Model_factory Model_factory_migration Model_factory_migrationSeeder Model_migration_controller_resource Model_migration_factory_controller_resource ; do
    case $action in
      Create_model)
        read -p "Model name like 'Flight': " model_name
        docker-compose exec php-fpm php artisan make:model $model_name
        exit 0
        ;;
      Model_migration)
        read -p "Model name like 'Flight': " model_name
        docker-compose exec php-fpm php artisan make:model $model_name -m
        exit 0
        ;;
      Model_factory)
        read -p "Model name like 'Flight': " model_name
        docker-compose exec php-fpm php artisan make:model $model_name -f
        exit 0
        ;;
      Model_factory_migration)
        read -p "Model name like 'Flight': " model_name
        docker-compose exec php-fpm php artisan make:model $model_name -mf
        exit 0
        ;;
      Model_factory_migrationSeeder)
        read -p "Model name like 'Flight': " model_name
        docker-compose exec php-fpm php artisan make:model $model_name -mfs
        exit 0
        ;;
      Model_migration_controller_resource)
        read -p "Model name like 'Flight': " model_name
        docker-compose exec php-fpm php artisan make:model $model_name -mcr
        exit 0
        ;;
      Model_migration_factory_controller_resource)
        read -p "Model name like 'Flight': " model_name
        docker-compose exec php-fpm php artisan make:model $model_name -mfcr
        exit 0
        ;;
      *)
        echo "ERROR! Please select between 1..3"
        ;;
    esac
  done
}

COLUMNS=1
function controller(){
  select action in Simple Resource Api; do
    case $action in
      Simple)
        read -p "Controller name like 'FlightController': " controller_name
        docker-compose exec php-fpm php artisan make:controller $controller_name
        exit 0
        ;;
      Resource)
        read -p "Controller name like 'FlightController': " controller_name
        docker-compose exec php-fpm php artisan make:controller $controller_name --resource
        exit 0
        ;;
      Api)
        read -p "Controller name like 'FlightController': " controller_name
        docker-compose exec php-fpm php artisan make:controller $controller_name --api
        exit 0
        ;;
      *)
        echo "ERROR! Please select between 1..3"
        ;;
    esac
  done
}

COLUMNS=1
function composerHandle(){
  select action in Composer_install Composer_update Composer_dump_autoload Composer_require; do
    case $action in
      Composer_install)
        read -p "Package name like 'laravel/ui': " package_name
        if [ -z "$package_name" ]; then
          echo "${tmagenta}ERROR! Package name is required. Please try again.${treset}"
        else
          docker-compose exec php-fpm composer require $package_name
        fi
        exit 0
        ;;
      Composer_update)
        docker-compose exec php-fpm composer update
        exit 0
        ;;
      Composer_dump_autoload)
        docker-compose exec php-fpm composer dump-autoload
        exit 0
        ;;
      Composer_require)
        read -p "Package name like 'laravel/ui': " package_name
        docker-compose exec php-fpm composer require $package_name
        exit 0
        ;;
      *)
        echo "ERROR! Please select between 1..3"
        ;;
    esac
  done
}

COLUMNS=1
function artisanHandle(){
  select action in Artisan ShowModel Tinker Develop; do
    case $action in
      Artisan)
        read -p "Artisan command like 'breez:install': " artisan_command
        docker-compose exec php-fpm php artisan $artisan_command
        ;;
      ShowModel)
        read -p "Model name like 'Flight': " model_name
        docker-compose exec php-fpm php artisan model:show $model_name
        ;;
      Tinker)
        docker-compose exec php-fpm php artisan tinker
        ;;
      Develop)
        docker-compose exec php-fpm php artisan develop
        ;;
      *)
        echo "ERROR! Please select between 1..3"
        ;;
    esac
  done
}

COLUMNS=1
function nodeHandler(){
  select action in NpmInstall NpmUpdate NpmRunDev NpmRunProd NpmRunBuild; do
    case $action in
      NpmInstall)
        docker-compose exec node npm install
        exit 0
        ;;
      NpmUpdate)
        docker-compose exec node npm update
        exit 0
        ;;
      NpmRunDev)
        docker-compose exec node npm run dev
        exit 0
        ;;
      NpmRunProd)
        docker-compose exec node npm run prod
        exit 0
        ;;
      NpmRunBuild)
        docker-compose exec node npm run build
        exit 0
        ;;
      *)
        echo "ERROR! Please select between 1..3"
        ;;
    esac
  done
}

COLUMNS=1
function middlewareHandler(){
  select action in Create_middleware; do
    case $action in
      Create_middleware)
        read -p ""Middleware" name like 'CheckAgeMiddleware': " middleware_name
        docker-compose exec php-fpm php artisan make:middleware $middleware_name
        exit 0
        ;;
      *)
        echo "ERROR! Please select between 1..3"
        ;;
    esac
  done 
}

function changeRequest(){
  request_name=$1
  file_name=$2
  file=app/Http/Requests/"$request_name/$file_name.php"
  sed -i 's/return false;/return true;/g' app/Http/Requests/"$request_name/$file_name.php"
  head -n -1 $file >> file.tmp
  cat <<TEST >> "file.tmp"
  protected function failedValidation(Validator \$validator)
  {
      throw new HttpResponseException(response()->json([
          'errors' => \$validator->errors(),
          'status' => true
      ], 422));
  }
TEST
        tail -1 $file >> file.tmp
        mv file.tmp $file
        head -n 3 $file >> file.tmp
        cat <<TEST >> "file.tmp"
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;
TEST
        tail -n +4 $file >> file.tmp
        mv file.tmp $file
}

COLUMNS=1
function requestHandler(){
  select action in Both Store Update; do
    case $action in
      Both)
        read -p "Enter request name like 'Worker': " request_name
        docker-compose exec php-fpm php artisan make:request "$request_name/StoreRequest"
        docker-compose exec php-fpm php artisan make:request "$request_name/UpdateRequest"
        changeRequest $request_name StoreRequest
        changeRequest $request_name UpdateRequest
        exit 0
        ;;
      Store)
        read -p "Enter request name like 'Worker': " request_name
        docker-compose exec php-fpm php artisan make:request "$request_name/StoreRequest"
        changeRequest $request_name StoreRequest
        exit 0
        ;;
      Update)
        read -p "Enter request name like 'Worker': " request_name
        docker-compose exec php-fpm php artisan make:request "$request_name/UpdateRequest"
        changeRequest $request_name UpdateRequest
        exit 0
        ;;
      *)
        echo "ERROR! Please select between 1..3"
        ;;
    esac
  done
}
resource="${tgreen}Resource${treset}"
routes="${tblue}Routes${treset}"
artisan="${tgreen}Artisan${treset}"
composer="${tblue}Composer${treset}"
migration="${tyellow}Migration${treset}"
model="${tgreen}Model${treset}"
controller="${tblue}Controller${treset}"
request="${tmagenta}Request${treset}"
middleware="${tblue}Middleware${treset}"
COLUMNS=8
select action in  $routes $artisan $composer $migration $model $controller $resource $request $middleware; do
  case $action in
    $routes)
      docker-compose exec php-fpm php artisan route:list
      exit 0
      ;;
    $artisan)
      artisanHandle
      ;;
    $composer)
      composerHandle
      ;;
    $migration)
      migrate
      ;;
    $model)
      model
      ;;
    $request)
      requestHandler
      exit 0
      ;;
    $controller)
      controller
      ;;
    $resource)
      read -p "Enter resource name like 'Worker, will be WorkerResource': " resource_name
      docker-compose exec php-fpm php artisan make:resource "${resource_name}Resource"
      exit 0
      ;;
    $middleware)
      middlewareHandler
      ;;
    *)
      echo "ERROR! Please select between 1..3"
      ;;
  esac
done

