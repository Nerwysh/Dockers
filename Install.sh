#!/bin/sh

######################## Pré-requis ########################
# Avoir un domain et les sous-domaines suivants :
# domain.tld,cloud.domain.tld,couchpotato.domain.tld,gateone.domain.tld,plexpy.domain.tld,plex.domain.tld
# rutorrent.domain.tld,rutorrent.couchpotato.domain.tld,rutorrent.sickrageen.domain.tld,
# rutorrent.sickragefr.domain.tld,sickrageen.domain.tld,sickragefr.domain.tld, plexrequests.domain.tld
#
# Domaines facutatifs : docker.domain.tld,logs.domain.tld,stats.domain.tld ,vpn.domain.tld
#
######################################################


######################################################
######################################################
echo "------------------------------------------------------";
echo "- Initialisation compléte du systéme";
echo "------------------------------------------------------";
echo "";
######################################################
######################################################

groupadd docker --gid=999
useradd docker --uid=1014 --gid=999 --create-home

######################################################
######################################################
echo "------------------------------------------------------";
echo "- Personnalisation";
echo "------------------------------------------------------";
echo "";
######################################################
######################################################

install_dir=$(pwd)


echo -n " Nouvelle installation (yes/no)? : "
read new_install
echo -n " Avez vous bien rempli sous_domaines.letsencrypt exemple : ( plex.sousdomain.domain.tld,cloud.sousdomain.domain.tld,...,...,etc ) (yes/no)? : "
read fichier
	if [ "${fichier}" = "yes" ]
	then
		echo ""
	else
		echo "Merci de faire le nécessaire !"
		exit
	fi
echo -n " Répertoire d'installation ? : "
read base_dir
echo -n " Domaine ? : "
read domain
echo -n " Login pour serveur web ? : "
read login
echo -n " Pass pour serveur web ? : "
read -s pass
echo ""
echo -n " Utilisez-vous amazon pour le stockage (yes/no)? : "
read amazon

	
######################################################
######################################################
echo "------------------------------------------------------";
echo "- Initialisation des variables d'environnement";
echo "------------------------------------------------------";
echo "";

sous_domains=$(cat sous_domaines.letsencrypt)
. /etc/profile
dcp="docker-compose -f ${base_dir}docker/docker_compose/docker-compose.yml"
echo "alias dcp=\"docker-compose -f ${base_dir}docker/docker_compose/docker-compose.yml\"">> /root/.bashrc

######################################################
######################################################

cd ${base_dir};

######################################################
######################################################
echo "------------------------------------------------------";
echo "- Installation et mise à jour des paquets";
echo "------------------------------------------------------";
echo "";
######################################################
######################################################
	
	apt-get -y update;
	apt-get -y upgrade;
	
######################################################
echo " -> installation de Nginx ..."
echo "";
	apt-get -y install nginx && echo " -> installation de Nginx OK !" || " -> installation de Nginx KO !"
echo "";

######################################################
echo " -> installation de Docker ..."
echo "";
	apt-get -y install apt-transport-https ca-certificates;
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main">/etc/apt/sources.list.d/docker.list
	apt-get -y update;
	apt-get -y install linux-image-extra-$(uname -r);
	apt-get -y install docker-engine;
	service docker start
	docker run hello-world && echo " -> installation de Docker OK !" || " -> installation de Docker KO !";
echo "";

######################################################
echo " -> installation de Docker-compose ..."
	apt-get -y install python-pip
	apt-get -y install python3-pip
	pip install --upgrade docker-compose && echo " -> installation de Docker-compose OK !" || " -> installation de Docker-compose KO !"

######################################################
echo " -> installation de Encfs ..."
echo "";
	apt-get -y install encfs && echo " -> installation de Encfs OK !" || " -> installation de Encfs KO !"
echo "";

######################################################
if [ "$amazon" = "yes" ]	
then
	echo " -> installation de Acd_cli ..."
	echo "";
	pip3 install --upgrade git+https://github.com/yadayada/acd_cli.git && echo " -> installation de Acd_cli OK !" || " -> installation de Acd_cli KO !"
else 
	echo "..."
fi

echo "";

######################################################

if [ "$amazon" = "yes" ]	
then

	echo " -> installation de unionfs-fuse ..."
	echo "";
	apt-get install -y unionfs-fuse && echo " -> installation de Unionfs-fuse OK !" || " -> installation de Unionfs-fuse KO !"
	echo "";
else 
	echo "";
fi

######################################################
echo " -> installation de Letsencrypt ..."
echo "";
	apt-get -y install git bc
	git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt && echo " -> installation de Letsencrypt OK !" || echo " -> installation de Letsencrypt KO !"
echo "";
echo " -> Génération des certificats ..."
echo "";
	service nginx stop
	/opt/letsencrypt/letsencrypt-auto certonly --standalone --agree-tos --no-redirect --text -d $domain,$sous_domains && echo " -> Certificats OK !" || " -> installation de Certificats KO !"
	service nginx start



######################################################
######################################################
echo "------------------------------------------------------";
echo "- Mise en place du FS";
echo "------------------------------------------------------";
echo "";
######################################################
######################################################

cd ${base_dir};
	if [ "$new_install" = "yes" ]
		then
			mkdir -p ${base_dir}docker/{keys,conf,data,partage}
			mkdir -p ${base_dir}docker/conf/nginx_local
			mkdir -p ${base_dir}docker/partage/{.amazon,.local,.perso,amazon,local,perso,media,aspirateur,waiting}
			mkdir -p ${base_dir}docker/partage/aspirateur/{aspirateur_couchpotato,aspirateur_nerwysh,aspirateur_sickrageen,aspirateur_sickragefr}
			mkdir -p ${base_dir}docker/partage/local/
			mkdir -p ${base_dir}docker/partage/waiting/{waiting_couchpotato,waiting_nerwysh,waiting_sickrageen,waiting_sickragefr}
			chown -R docker:docker ${base_dir}docker/
			chmod -R 777 ${base_dir}docker/partage/waiting/ ;
			chmod -R 777 ${base_dir}docker/partage/aspirateur/ ;
			echo " -> Arborescence OK"
		else
		echo "------------------------------------------------------";
		echo "- Restauration des anciennes données";
		echo "------------------------------------------------------";
		echo "";
		echo "Vérification de l'existence de l'archive";
		echo "";
	
			if [ -e "$/backup.tar.gz" ]
				then
					echo " -> Backup en cours ...";
					echo "";
					tar -xvzf backup.tar.gz -C ${base_dir}
					echo "";
					echo " -> Fin de la restauration.";
					echo " -> Arborescence OK";
					echo "";
				else
				echo "";
				echo "L'archive de restauration n'existe pas.";
				echo "";
				
			fi
	fi

######################################################
######################################################
echo "------------------------------------------------------";
echo "- Montage des FS";
echo "------------------------------------------------------";
######################################################
######################################################


if [ "$amazon" = "yes" ]	
	then
			
			echo "Montage du répertoire /home/docker/partage/.amazon : "
			echo ""

			acd_cli init
			acd_cli mount ${base_dir}docker/partage/.amazon/ && echo "" echo " -> Montage OK !" || echo " -> Montage KO"
			acd_cli sync
			
			echo ""
	else
			echo ""
fi

echo "Montage Encfs en cours..."
echo ""

montage_encfs()
{

echo ""

if [ -e "${base_dir}docker/keys/.encfs6.xml"  ]
		
        then 
			echo " === Montage $source vers $destination en cours === "
			echo -n Password:
			read -s password
			echo ""
			ENCFS6_CONFIG="${base_dir}docker/keys/.encfs6.xml" encfs --extpass="echo $password" --public $source $destination && echo " === Montage $source vers $destination OK === " || echo " ERROR :( "
        else
			encfs --public $source $destination && echo " === Montage $source vers $destination OK === " || echo " ERROR "
fi
}

if [ "$amazon" = "yes" ]	
	then
		source="${base_dir}docker/partage/.amazon/"
		destination="${base_dir}docker/partage/amazon/"
		montage_encfs $source $destination
	else
		echo ""
fi

source="${base_dir}docker/partage/.local/"
destination="${base_dir}docker/partage/local"
montage_encfs $source $destination./

if [ "$amazon" = "yes" ]	
then
	echo "Montage Unionfs-fuse en cours..."
	echo ""
	unionfs-fuse -o allow_other -o cow ${base_dir}docker/partage/local=RW:${base_dir}docker/partage/amazon=RO ${base_dir}docker/partage/media && echo " -> Montage ${base_dir}docker/partage/media OK" || echo " -> Montage /home/docker/partage/media
	 ERROR"
	echo ""
else
	echo ""
fi


######################################################
######################################################
echo "------------------------------------------------------";
echo "- Déploiement des Applications";
echo "------------------------------------------------------";
######################################################
######################################################
cd $install_dir;

if [ -e "${base_dir}"docker/docker_compose/docker-compose.yml ]
then
	$dcp up -d
else 
	mkdir ${base_dir}docker/docker_compose/
	sed -i "s/password/$pass/g" docker-compose.yml
	sed -i "s/domain.tld/$domain/g" docker-compose.yml
	cp docker-compose.yml "${base_dir}"docker/docker_compose/
	$dcp up -d
fi



######################################################
######################################################
echo "------------------------------------------------------";
echo "- Configuration des applicatifs";
echo "------------------------------------------------------";
######################################################
######################################################

cd $install_dir;

echo "Configuration de Nginx..."
echo ""
sed -i "s/domain.tld/$domain/g" *.conf
cp *.conf ${base_dir}docker/conf/nginx_local/
cp -s ${base_dir}docker/conf/nginx_local/* /etc/nginx/sites-enabled/
PASSWORD="$pass";SALT="$(openssl rand -base64 3)";SHA1=$(printf "$PASSWORD$SALT" | openssl dgst -binary -sha1 | sed 's#$#'"$SALT"'#' | base64);printf "$login:{SSHA}$SHA1\n" > ${base_dir}docker/keys/.htpasswd
service nginx reload


