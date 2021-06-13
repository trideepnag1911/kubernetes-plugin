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
kubectl get deploy | grep $App > /dev/null
if [ $? -eq 0 ]
then
Deployed_App=deployment
else
kubectl get sts | grep $App > /dev/null
if [ $? -eq 0 ]
then
Deployed_App=statefulset
else
kubectl get replicationcontroller | grep $App > /dev/null
if [ $? -eq 0 ]
then
Deployed_App=replicationcontroller
else
echo "App not found"
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
kubectl describe svc $service | grep -i selector | grep -i $lables > /dev/null
if [ $? -eq 0 ]
then
echo $service >> mapped_services.txt
else
echo $lables "Not mappedt With Any Service" >> service_mapping.txt
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
configmap=`kubectl get $Deployed_App $App -o json | jq '.spec.template.spec.volumes[].configMap.name' | sed 's/null//g'| sed 's/"//g'`
for conf in $configmap
do
kubectl get cm $conf | grep -v NAME >> configmaps.txt
done

# Find out mapped PVC
echo "NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE" > pvc.txt
PVC=`kubectl get $Deployed_App $App -o json | jq '.spec.template.spec.volumes[].persistentVolumeClaim.claimName' | sed 's/null//g' | sed 's/"//g'`
for pvc in $PVC
do
kubectl get pvc $pvc | grep -v NAME >> pvc.txt
done

# Find out mapped secrets
echo -e "NAME"'\t'"TYPE"'\t'"DATA"'\t'"AGE" > secrets.txt
SECRETS=`kubectl get $Deployed_App $App -o json | jq '.spec.template.spec.volumes[].secret.secretName' | sed 's/null//g' | sed 's/"//g'`
for secrets in $SECRETS
do
kubectl get secret $secrets | grep -v NAME >> secrets.txt
done
# Find out mapped pod name
echo "NAME        READY   STATUS    RESTARTS   AGE" > pods.txt
POD_NAME=`kubectl get $Deployed_App $App -o json | jq '.metadata.name' | sed 's/"//g'`
PODS=`kubectl get pods | grep $POD_NAME | awk '{print $1}'`
for pods in $PODS
do
kubectl get pods $pods | grep -v NAME >> pods.txt
done

# Find out Container Resources
kubectl get $Deployed_App $App -o json | jq '.spec.template.spec.containers[].resources' | sed 's/{//g' | sed 's/}//g' | sed '
s/,//g'| sed 's/"//g' > resource.txt

#echo "ConfigMap mounted are :-" $configmap
#echo "PVC mounted are :-" $PVC
#echo "Secrets mounted are :-" $SECRETS
#echo "Pod running with name :-" $POD
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
fi
rm -f pods.txt resource.txt pvc.txt secrets.txt service_mapping.txt configmaps.txt mapped_services.txt
