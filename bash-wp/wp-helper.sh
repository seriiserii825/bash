#! /bin/bash

wpShowPages(){
  wp post list --post_type=page --orderby=title --order=asc
}
