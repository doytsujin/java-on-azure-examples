#!/bin/bash
cd ..


if [[ -z $RESOURCE_GROUP ]]; then
export RESOURCE_GROUP=java-on-azure-$RANDOM
export REGION=southcentralus
fi

az group create --name $RESOURCE_GROUP --location $REGION
if [[ -z $ACR_NAME ]]; then
export ACR_NAME=acreg$RANDOM
fi
az acr create \
--name $ACR_NAME \
--resource-group $RESOURCE_GROUP \
--sku Basic \
--admin-enabled true

cd containers/acr/helidon

mvn package
export ACR_HELIDON_IMAGE=helidon:latest

az acr build --registry $ACR_NAME --resource-group $RESOURCE_GROUP --image $ACR_HELIDON_IMAGE .

cd ../../..


if [[ -z $RESOURCE_GROUP ]]; then
export RESOURCE_GROUP=java-on-azure-$RANDOM
export REGION=southcentralus
fi

az group create --name $RESOURCE_GROUP --location $REGION
az upgrade --yes || true
az extension add --name containerapp --upgrade
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights
if [[ -z $ACA_ENVIRONMENT_NAME ]]; then
export ACA_ENVIRONMENT_NAME=aca$RANDOM
export ACA_REGION=westus
fi
az containerapp env create \
--name $ACA_ENVIRONMENT_NAME \
--resource-group $RESOURCE_GROUP \
--location "$ACA_REGION"
export ACA_HELIDON=helidon

az containerapp create \
--name $ACA_HELIDON \
--resource-group $RESOURCE_GROUP \
--environment $ACA_ENVIRONMENT_NAME \
--image $ACR_NAME.azurecr.io/$ACR_HELIDON_IMAGE \
--target-port 8080 \
--ingress 'external' \
--registry-server $ACR_NAME.azurecr.io \
--min-replicas 1

echo $(az containerapp show \
--resource-group $RESOURCE_GROUP \
--name $ACA_HELIDON \
--query properties.configuration.ingress.fqdn \
--output tsv)/greet
sleep 60
export URL=https://$(az containerapp show --resource-group $RESOURCE_GROUP --name $ACA_HELIDON --query properties.configuration.ingress.fqdn --output tsv)/greet
export RESULT=$(curl $URL)
az group delete --name $RESOURCE_GROUP --yes || true
if [[ "$RESULT" != *"Hello World"* ]]; then
echo "Response did not contain 'Hello World'"
exit 1
fi