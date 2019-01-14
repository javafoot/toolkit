#! /bin/bash
##==== LORD JESUS CHRIST LOVE EVERY ONE ====
##==== Code in the Name of LORD JESUS CHRIST ====

## Feature: Export configuration of the old Jenkins config.xml, 2.60.3 and import it to the new one, 2.150.1.

workDir=$(dirname $0)
tmplFile=$workDir/config.xml.template.jenkins
oConfigFile=$1
nConfigFile=$2
jenkinsName=$3
jns=$4

function exportConf() {
    ls -lh $oConfigFile
    authorizationStrategy=$(xmllint --xpath '/hudson/authorizationStrategy/permission' $oConfigFile)
    added='          <nodeProperties/>          <yaml></yaml>          <podRetention class="org.csanchez.jenkins.plugins.kubernetes.pod.retention.Default"/>'
    cicdPod=$(xmllint --xpath '/hudson/clouds/org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud/templates/org.csanchez.jenkins.plugins.kubernetes.PodTemplate[1]/*' $oConfigFile|tr -d '\n')$added
    k8sInfo="      "$(xmllint --xpath '/hudson/clouds/org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud/*[self::containerCap or self::retentionTimeout or self::connectTimeout or self::readTimeout or self::maxRequestsPerHost]' $oConfigFile)
    archViewJobNames="        "$(xmllint --xpath '/hudson/views/listView[name="arch"]/jobNames/string' $oConfigFile)
    archHotfixViewJobNames="        "$(xmllint --xpath '/hudson/views/listView[name="arch-hotfix"]/jobNames/string' $oConfigFile)
    globalNodeProperties=$(xmllint --xpath '/hudson/globalNodeProperties/hudson.slaves.EnvironmentVariablesNodeProperty/envVars/tree-map' $oConfigFile|sed -e '/tree-map/d' -e '/default/d' -e '/comparator/d'|tr -d '\n')
}

exportConf
tmpConfigFile=$workDir/jenkinsConfigFile.tmp

## Import to new Jenkins
sed -e "s|##authorizationStrategy##|$authorizationStrategy|" -e "s|##jenkinsCicdPodTemplate##|$cicdPod|" -e "s|##jns##|$jns|" -e "s|##jenkinsName##|$jenkinsName|" -e "s|##k8sInfo##|$k8sInfo|" -e "s|##archViewJobNames##|$archViewJobNames|" -e "s|##archHotfixViewJobNames##|$archHotfixViewJobNames|" -e "s|##globalNodeProperties##|$globalNodeProperties|" $tmplFile > $tmpConfigFile
xmllint --format $tmpConfigFile > $nConfigFile
rm -fv $tmpConfigFile
echo "Imported the config from $oConfigFile to $nConfigFile."

##==== Glory to GOD ====
