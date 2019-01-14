#! /bin/bash
##==== LORD JESUS CHRIST LOVE EVERY ONE ====
##==== Code in the Name of LORD JESUS CHRIST ====

## Feature: Sync Jenkins config files to the new Jenkins.

if [[ "$1" == "/"* ]]; then
    oJenkins=$1
else
    oJenkins=/data/nfs/$1
fi
nJenkins=##newJenkins##
if [ $# -eq 0 -o ! -e "$oJenkins" ]; then
    echo "Wrong the old Jenkins folder: $oJenkins!"
    exit -1
fi
workDir=$(dirname $0)

jenkinsName=##jenkinsName##
jns=##jns##
oConfigFile=$oJenkins/config.xml
oJenkinsLoc=$oJenkins/jenkins.model.JenkinsLocationConfiguration.xml
oHudsonMailer=$oJenkins/hudson.tasks.Mailer.xml
oCredentials=$oJenkins/credentials.xml
nConfigFile=$nJenkins/config.xml
nJenkinsLoc=$nJenkins/jenkins.model.JenkinsLocationConfiguration.xml
nHudsonMailer=$nJenkins/hudson.tasks.Mailer.xml
nCredentials=$nJenkins/credentials.xml

## Back up the config files of new Jenkins
echo "Backing up config files of new Jenkins......"
cp -v $nConfigFile $nConfigFile.origin
cp -v $nJenkinsLoc $nJenkinsLoc.origin
cp -v $nHudsonMailer $nHudsonMailer.origin

source $workDir/import2ConfigXml.sh $oConfigFile $nConfigFile $jenkinsName $jns

mailLine=$(grep adminAddress $oJenkinsLoc|xargs)
sed -i "s|<adminAddress></adminAddress>|$mailLine|" $nJenkinsLoc
echo "Copied the adminAddress line in the old $oJenkinsLoc to the new $nJenkinsLoc."

mailer=$(sed -e '/?xml/d' -e '/hudson.tasks.Mailer/d' $oHudsonMailer)
echo "<?xml version='1.1' encoding='UTF-8'?>" > $nHudsonMailer
echo '<hudson.tasks.Mailer_-DescriptorImpl plugin="mailer@1.22">' >> $nHudsonMailer
echo "$mailer" >> $nHudsonMailer
echo "</hudson.tasks.Mailer_-DescriptorImpl>" >> $nHudsonMailer
echo "copied the content of the old $oHudsonMailer to the new $nHudsonMailer."

rsync -ah $oJenkins/users $nJenkins
echo "Synced accounts of $oJenkins/users to $nJenkins."
rsync -ah $oJenkins/jobs $nJenkins
echo "Synced jobs of $oJenkins/jobs to $nJenkins."
cp -fv $oCredentials $nCredentials

##==== Glory to GOD ====
