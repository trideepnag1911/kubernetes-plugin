#!/bin/bash

#####################################################

####### App-mapper Version 1.0                #######

####### Author Trideep Nag                    #######

#######                                       #######

####### Kubernetes Plugin                     #######

#######                                       #######

#######                                       #######

#####################################################

App=$1

 

if [ $App == help ]

then

echo " This is a Kubernetes Plugin to get detailed information of the Application Deployed as a Kubernetes Object"

echo " Usage of this Plugin is as follows"

echo "kubectl appmapper <Name-Of-The-Application-Deployed>"

echo "Example:-"

echo "kubectl appmapper jenkins"

else

# Check if the application is deployed as deployment or statefulset or a replicationcontroller

kubectl get deploy $App > /dev/null 2>&1

if [ $? -eq 0 ]

then

Deployed_App=deployment

else

kubectl get sts $App > /dev/null  2>&1

if [ $? -eq 0 ]

then

Deployed_App=statefulset

else

kubectl get replicationcontroller $App > /dev/null  2>&1

if [ $? -eq 0 ]

then

Deployed_App=replicationcontroller

else

kubectl get jobs $App > /dev/null  2>&1

kubectl get replicationcontroller $App > /dev/null  2>&1

if [ $? -eq 0 ]

then

Deployed_App=job

else

echo "App not found"

fi

fi

fi

fi

fi
 

 

# Check lables of the App

 

lable=`kubectl describe $Deployed_App $App | grep -i labels | grep -v none | awk '{print $NF}' | uniq`

 

# Check how mane application is having same Lables as selector

> mapped_services.txt

echo -e "Service_Name"  '\t' "Service_Type" '\t' "Service_IP" '\t' "Service_Ports" > service_mapping.txt

 

for lables in $lable

do

svc=`kubectl get svc | awk '{print $1}'| grep -v NAME`

for service in $svc

do

kubectl describe svc $service | grep -i selector | grep -i $lables > /dev/null 2>&1

if [ $? -eq 0 ]

then

echo $service >> mapped_services.txt

else

echo $lables "Not mapped With Any Service" > /dev/null 2>&1

fi

done

done

 

# Detailes of Mapped services

for details in `cat mapped_services.txt`

do

kubectl get svc $details |grep -v NAME | awk '{print $1, "\t"$2, "\t"$3, "\t"$5}' >> service_mapping.txt

done

 

 

# Find out configMaps attached

echo -e "NAME" '\t'"DATA" '\t'"AGE" > configmaps.txt

 

configmap=`kubectl get $Deployed_App $App -o json | jq '.spec.template.spec.volumes[].configMap.name' 2> /dev/null | sed 's/null//g'| sed 's/"//g'`

for conf in $configmap

do

kubectl get cm $conf | grep -v NAME >> configmaps.txt

done

 

# Find out mapped PVC

echo "NAME          STATUS        VOLUME                                 CAPACITY   ACCESS MODES   STORAGECLASS   AGE" > pvc.txt

if [ $Deployed_App == statefulset ]

then

PVC=`kubectl get $Deployed_App $App -o json | jq '.spec.volumeClaimTemplates[].metadata.name' | sed 's/"//g'`

for pvc in $PVC

do

kubectl get pvc  | grep $pvc | grep -v NAME >> pvc.txt

done

else

if [ $Deployed_App == deployment ]

then

PVC=`kubectl get $Deployed_App $App -o json | jq '.spec.template.spec.volumes[].persistentVolumeClaim.claimName' 2> /dev/null | sed 's/null//g' | sed 's/"//g'`

for pvc in $PVC

do

kubectl get pvc $pvc | grep -v NAME >> pvc.txt

done

else

if [ $Deployed_App == job ]

then

PVC=

else

echo "PVC not found" > /dev/null 2>&1

fi

fi

fi

 

# Find out mapped secrets

echo -e "NAME"'\t'"TYPE"'\t'"DATA"'\t'"AGE" > secrets.txt

SECRETS=`kubectl get $Deployed_App $App -o json | jq '.spec.template.spec.volumes[].secret.secretName' 2> /dev/null | sed 's/null//g' | sed 's/"//g'`

for secrets in $SECRETS

do

kubectl get secret $secrets | grep -v NAME >> secrets.txt

done

# Find out mapped pod name

echo "NAME                                 READY   STATUS    RESTARTS   AGE" > pods.txt

POD_NAME=`kubectl get $Deployed_App $App -o json | jq '.metadata.name' 2> /dev/null | sed 's/"//g'`

PODS=`kubectl get pods | grep $POD_NAME | awk '{print $1}'`

for pods in $PODS

do

kubectl get pods $pods | grep -v NAME >> pods.txt

done

 

# Find out Container Resources

kubectl get $Deployed_App $App -o json | jq '.spec.template.spec.containers[].resources'  2> /dev/null | sed 's/{//g' | sed 's/}//g' | sed 's/,//g'| sed 's/"//g' > resource.txt

 

# Find out mapped Istio Virtual Service

> vs1.txt

VS=`kubectl get vs 2> /dev/null | grep -v NAME | awk '{print $1}'`

for svc in `cat mapped_services.txt | uniq`

do

for vs in $VS

do

kubectl get vs $vs -o json |  jq '.spec' | grep tcp > /dev/null 2>&1

if [ $? -eq 0 ]

then

kubectl get vs $vs -o json | jq '.spec.tcp[].route[].destination.host' | sed 's/"//g' | grep $svc > /dev/null 2>&1

if [ $? -eq 0 ]

then

echo $vs > vs1.txt

else

echo "No VS Mapped" > /dev/null 2>&1

fi

else

kubectl get vs $vs -o json | jq '.spec.http[].route[].destination.host' | sed 's/"//g' | grep $svc > /dev/null 2>&1

if [ $? -eq 0 ]

then

echo $vs > vs1.txt

else

echo "No VS Mapped" > /dev/null 2>&1

fi

fi

done

done

 

echo "NAME                     GATEWAYS                              HOSTS                                                    AGE" > VS.txt

for VS in `cat vs1.txt`

do

kubectl get vs $VS | grep -v NAME >> VS.txt

done

 

 

tput cup 50 30 ; echo "App Name is :-" $App

tput cup 50 30 ; echo "#########################"

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "          \  /           "

tput cup 50 30 ; echo "           \/            "

tput cup 50 30 ; echo "App Is Deployed As :-" $Deployed_App

tput cup 50 30 ; echo "#########################"

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "          \  /           "

tput cup 50 30 ; echo "           \/            "

tput cup 50 30 ; echo "Mapped Service Details"

tput cup 50 30 ; echo "#########################"

line=`cat service_mapping.txt | wc -l`

for Line in $(seq 1 $line)

do

tput cup 50 30; sed ''$Line'!d' service_mapping.txt

done

tput cup 50 30 ; echo "#########################"

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "          \  /           "

tput cup 50 30 ; echo "           \/            "

tput cup 50 30 ; echo "Mapped ConfigMaps Are :-" $configmap

tput cup 50 30 ; echo "#########################"

line=`cat configmaps.txt | wc -l`

for Line in $(seq 1 $line)

do

tput cup 50 30; sed ''$Line'!d' configmaps.txt

done

tput cup 50 30 ; echo "#########################"

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "          \  /           "

tput cup 50 30 ; echo "           \/            "

tput cup 50 30 ; echo "Mapped Secrets Are :-" $SECRETS

tput cup 50 30 ; echo "#########################"

line=`cat secrets.txt | wc -l`

for Line in $(seq 1 $line)

do

tput cup 50 30; sed ''$Line'!d' secrets.txt

done

tput cup 50 30 ; echo "#########################"

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "          \  /           "

tput cup 50 30 ; echo "           \/            "

tput cup 50 30 ; echo "Mapped PVC Are :-" $PVC

tput cup 50 30 ; echo "#########################"

cat pvc.txt

tput cup 50 30 ; echo "#########################"

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "          \  /           "

tput cup 50 30 ; echo "           \/            "

tput cup 50 30 ; echo "Mapped Pods Are :-" $PODS

tput cup 50 30 ; echo "#########################"

line=`cat pods.txt | wc -l`

for Line in $(seq 1 $line)

do

tput cup 50 30; sed ''$Line'!d' pods.txt

done

tput cup 50 30 ; echo "#########################"

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "          \  /           "

tput cup 50 30 ; echo "           \/            "

tput cup 50 30 ; echo "Pod Resource Configuration :-"

tput cup 50 30 ; echo "#########################"

line=`cat resource.txt | wc -l`

for Line in $(seq 1 $line)

do

tput cup 50 30; sed ''$Line'!d' resource.txt

done

tput cup 50 30 ; echo "#########################"

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "           ##            "

tput cup 50 30 ; echo "          \  /           "

tput cup 50 30 ; echo "           \/            "

tput cup 50 30 ; echo "Mapped Istio Virtual Services Are:-" `cat vs1.txt`

tput cup 50 30 ; echo "#########################"

line=`cat VS.txt | wc -l`

for Line in $(seq 1 $line)

do

tput cup 50 30; sed ''$Line'!d' VS.txt

done

rm -f pods.txt resource.txt pvc.txt secrets.txt service_mapping.txt configmaps.txt mapped_services.txt VS.txt vs1.txt
