#! /bin/bash
##==== LORD JESUS CHRIST LOVE EVERY ONE ====
##==== Code in the Name of LORD JESUS CHRIST ====

## Feature: Deploy Jenkins by Helm and migrate all data on the running Jenkins to this one.

JPVFILE=jenkins-helm-pv.yaml
HELMVALUEFILE=jenkins-helm-values.yaml
djName=jenkinsh

init() {
    read -p "JenkinsName? [$djName] " jenkinsName
    if [ "$jenkinsName" = '' ]; then
        jenkinsName=$djName
    fi
    read -p 'Suffix of Jenkins URL?(Finally full URL with "http://") ' jenkinsURL
    if [ "$jenkinsURL" = '' ]; then
        echo 'Do nothing. Exit!'
        exit -1
    fi
    if [[ "$jenkinsURL" == "http"* ]]; then
        jenkinsURL=${jenkinsURL#*://}
    else
        jenkinsURL=$jenkinsName.$jenkinsURL
    fi
    read -p 'Namespace where Jenkins will be installed and that must has configMap and secret for Jenkins? ' jns
    if [ "$jns" = '' ]; then
        echo 'Do nothing. Exit!'
        exit -1
    fi
    read -p 'PV server with SSH login without password? ' pvServer
    if [ "$pvServer" = '' ]; then
        echo 'Do nothing, Exit!'
        exit -1
    fi
    tmpShellPath=/tmp/jenkinsUpgrade_${pvServer}_${jenkinsName}
    mkdir $tmpShellPath
    jenkinsLocation=/data/nfs/$jenkinsName

    read -p "Folder name of the old Jenkins on NFS(For sync the data to the new. You may leave it blank): " oldJenkinsFolder
    read -p "NodeSelector for Jenkins pod(You may leave it blank): " nodeSelector
    echo -e "\n\n============================================\n"
    echo jenkinsName: $jenkinsName
    echo jenkinsURL: $jenkinsURL
    echo Namesapce: $jns
    echo jenkinsLocation@pvServer: $jenkinsLocation on $pvServer
    echo $pvServer has SSH login without password!!
    echo oldJenkinsFolder on NFS: $oldJenkinsFolder
    echo nodeSelector: $nodeSelector
    read -p "Go ahead? [Y/N] " yes
    if [ ! "$yes" = 'Y' ]; then
        exit -1
    fi
}

function deploy() {
    echo Creating PV for $jenkinsName ......
    sed -e "s/jenkinsName/$jenkinsName/" -e "s/pvServer/${pvServer#*@}/" ./$JPVFILE > $tmpShellPath/$JPVFILE
    ssh $pvServer "mkdir -p ${jenkinsLocation}; chown -R 1000:1000 $jenkinsLocation"
    kubectl apply -f $tmpShellPath/$JPVFILE

    echo Helm deploying Jenkins......
    sed -e "s/jenkinsName/$jenkinsName/" -e "s/jenkinsURL/$jenkinsURL/" ./$HELMVALUEFILE > $tmpShellPath/$HELMVALUEFILE
    if [ "$nodeSelector" != "" ]; then
        echo '  NodeSelector:' >> /tmp/$HELMVALUEFILE
        echo '    beta.kubernetes.io/os: linux' >> /tmp/$HELMVALUEFILE
        echo "    kubernetes.io/hostname: $nodeSelector" >> /tmp/$HELMVALUEFILE
        echo '  Tolerations:' >> /tmp/$HELMVALUEFILE
        echo '  - effect: NoSchedule' >> /tmp/$HELMVALUEFILE
        echo '    key: node-role.kubernetes.io/cicd' >> /tmp/$HELMVALUEFILE
    fi
    helm --debug --name $jenkinsName --namespace $jns -f $tmpShellPath/$HELMVALUEFILE install stable/jenkins
}

function prepareConfigSync() {
    sed -e "s|##newJenkins##|$jenkinsLocation|" -e "s|##jenkinsName##|$jenkinsName|" -e "s|##jns##|$jns|" syncJenkinsConfig.sh > $tmpShellPath/syncJenkinsConfig.sh
    chmod 755 $tmpShellPath/syncJenkinsConfig.sh
    cp -fv import2ConfigXml.sh $tmpShellPath
    cp -fv config.xml.template.jenkins $tmpShellPath
    (cd /tmp; zip -r9 $tmpShellPath.zip ${tmpShellPath:5})
    echo scping to ${pvServer}......
    scp $tmpShellPath.zip $pvServer:/tmp
    ssh $pvServer "unzip $tmpShellPath.zip -d /tmp"
    echo -e "\n\n**************************************"
    echo "Shell script to sync Jenkins config files has been placed $tmpShellPath on $pvServer!"
    if [ "$oldJenkinsFolder" = "" ]; then oldJenkinsFolder='<$oldJenkins.foldername.on.nfs>'; fi
    echo 'You may manually run the command "'ssh $pvServer \'$tmpShellPath/syncJenkinsConfig.sh $oldJenkinsFolder\' '", after the new Jenkins pod is started up completely!!!'
}

## Checkign the pod if started up
function checkPodStartedup() {
    while [ 1 ]; do
        ok=($(kubectl get po -n $jns|grep $jenkinsName|awk '{if ($3 != "Terminating") print $1,$2}'))
        if [ "${ok[1]}" = "1/1" ]; then
            echo "${ok[0]} started up."
            break
        fi
        echo ${ok[0]} is starting......
        sleep 5
    done
}

init
deploy
echo -e "\n-----------------------------------------\n"
jenkinsPod=$(kubectl get po -n $jns|grep $jenkinsName |awk '{print $1}')
podCmd="kubectl get po $jenkinsPod -n $jns"
echo "Helm has deployed Jenkins: $podCmd"
prepareConfigSync
echo -e "\n-----------------------------------------\n"
echo Checking the pod $jenkinsPod, you may stop this script, if the pod pedning long time.
checkPodStartedup

## Need to sync the data of the old Jenkins.
if [ "$oldJenkinsFolder" != "" ]; then
    echo -e "\n\nDoing on $pvServer......\n"
    ssh $pvServer "$tmpShellPath/syncJenkinsConfig.sh $oldJenkinsFolder"
    echo Restarting the pod......
    kubectl delete po $jenkinsPod -n $jns
    checkPodStartedup
    echo "Synced data of the old Jenkins to the new. Congratulations!"
    echo "You may access your new Jenkins https://$jenkinsURL with accounts in the old Jenkins."
fi
##==== Glory to GOD ====
