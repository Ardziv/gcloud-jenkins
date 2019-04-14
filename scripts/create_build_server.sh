. ../settings.conf
gcloud compute instances create $instancename --metadata-from-file startup-script=./install_jenkins.sh --image-project "$image_project" --image "$image" --machine-type "$machine_type" --zone "$zone" 

gcloud compute firewall-rules create jenkins-web-port --allow tcp:8080


