#!/bin/bash
cd ..


if [[ -z $RESOURCE_GROUP ]]; then
export RESOURCE_GROUP=java-on-azure-$RANDOM
export REGION=westus2
fi

az group create --name $RESOURCE_GROUP --location $REGION
export MYSQL_NAME=mysql-$RANDOM
export MYSQL_USERNAME=mysql
export MYSQL_PASSWORD=p#ssw0rd-$RANDOM
if [[ -z $MYSQL_NAME ]]; then
export MYSQL_NAME=mysql-$RANDOM
export MYSQL_USERNAME=mysql
export MYSQL_PASSWORD=p#ssw0rd-$RANDOM
fi
az mysql server create \
--admin-user $MYSQL_USERNAME \
--admin-password $MYSQL_PASSWORD \
--name $MYSQL_NAME \
--resource-group $RESOURCE_GROUP \
--sku B_Gen5_1 \
--ssl-enforcement Disabled

az group delete --name $RESOURCE_GROUP --yes || true