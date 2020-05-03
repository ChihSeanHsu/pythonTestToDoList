#!/bin/bash
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 ACCOUNT_ID REGION prod|dev VERSION" >&2
  exit 1
fi

if [ "$3" != "prod" ] && [ "$3" != "dev" ]; then
  echo "ENV only prod and dev" >&2
  exit 1
fi

account=$1
region=$2
env=$3
version=$4

ecr_name="$account.dkr.ecr.$region.amazonaws.com"

docker login -u AWS -p $(aws ecr get-login-password) "https://$ecr_name"

# pull image version
docker pull $ecr_name/todo-list-app:$version
if [ "$?" != "0" ];then
    # if not tag latest as version we want
    docker tag todo-list-app:latest $ecr_name/todo-list-app:$version
    docker push $ecr_name/todo-list-app:$version
fi

docker tag $ecr_name/todo-list-app:$version $ecr_name/todo-list-app:$env
docker push $ecr_name/todo-list-app:$env


aws ecs update-service --force-new-deployment --service "$env-todo-list-service" --cluster "$env-todo-list-cluster"