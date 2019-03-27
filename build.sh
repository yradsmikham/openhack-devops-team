#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "LIST CONTENT: "
ls -a

az login -u 'hacker6@OTAPRD170ops.onmicrosoft.com' -p 'haAWU@8$HbU0'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)
#script requires latest version of .netcore to be installed ()

echo "Build Flavor:" $buildFlavor
echo "Resource Group:" $resourceGroupName
echo "Image:" $imageTag
echo "Relative save location:" $relativeSaveLocation
echo "DNS Url:" $dnsUrl

#get the acr repository id to tag image with.
ACR_ID=`az acr list -g $resourceGroupName --query "[].{acrLoginServer:loginServer}" --output json | jq .[].acrLoginServer | sed 's/\"//g'`

echo "ACR ID: "$ACR_ID

#Get the acr admin password and login to the registry
acrPassword=$(az acr credential show -n $registryName -o json | jq -r '[.passwords[0].value] | .[]')

docker login $ACR_ID -u $registryName -p $acrPassword
echo "Authenticated to ACR with username and password"

TAG=$ACR_ID"/devopsoh/"$imageTag

echo "TAG: "$TAG

cd apis/poi/web

docker build . -t $TAG

docker push $TAG

echo -e "\nSuccessfully pushed image: "$TAG

installPath="apis/poi/charts/mydrive-poi"
echo -e "\nhelm install from: " $installPath "\n\n"

BASE_URI='http://'$dnsUrl
echo "Base URI: $BASE_URI"
helm install $installPath --name api-poi --set repository.image=$TAG,env.webServerBaseUri=$BASE_URI,ingress.rules.endpoint.host=$dnsUrl
