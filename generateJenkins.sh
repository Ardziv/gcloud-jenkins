. ./settings.conf
mkdir $tmpdir
cd scripts
# Jenkins will need to be configured to work with your specific LDAP provider. 
# Here, we generate a groovy script to make those changes. This script will then be uploaded to the provisioned VM and run
./generateCustomLDAPScript.sh > $tmpdir/configure_ldap.groovy
cp *.groovy $tmpdir
echo "Building server on Google Cloud, this may  take a few moments..."
./create_build_server.sh
sleep 60
echo reticulating splines....
gcloud compute scp $tmpdir/*.groovy  $instancename:~/.  --zone $zone
echo copied groovy scripts over to remote server
echo waiting for jenkins instance to come up

# Wait for Jenkins to start up
#while ! gcloud compute ssh $instancename --zone $zone --command 'pidof java' >> /dev/null;
until pids=$(gcloud compute ssh $instancename --zone $zone --command 'pidof java')
do   
    sleep 88
done

echo configuring security
gcloud compute ssh $instancename --zone $zone --command 'curl --data-urlencode "script@./configure_ldap.groovy" http://localhost:8080/scriptText'

echo "generating keys and configuring SSH for git clone"
gcloud compute ssh $instancename --zone $zone --command "sudo runuser -l jenkins -c 'ssh-keygen -t rsa -N "password" -C "$email" -f "~/.ssh/id_rsa"';sudo cp /var/lib/jenkins/.ssh/id_rsa.pub ~ "

echo "installing plugins (this will restart Jenkins)"
gcloud compute ssh $instancename --zone $zone --command "curl --data-urlencode 'script@./configurePlugins.groovy' -u${managerUser}:${managerPassword} http://localhost:8080/scriptText"

#Copy public key back over
gcloud compute scp $instancename:~/id_rsa.pub ../id_rsa.pub  --zone $zone

echo Executed script to connect Jenkins to LDAP
echo ===========================================
rm -Rf $tmpdir
gcloud compute instances describe --zone $zone  $instancename | grep natIP | awk '{print "Your new Jenkins server is running at http://" $2 ":8080"}'
echo "To connect your Jenkins instance to your Github, add the key in id_rsa.pub to your GitHub project"
echo -n "Administrator Password : "
gcloud compute ssh $instancename --zone $zone --command 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
echo 
echo 
echo "Ok, that's all done."
