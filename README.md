# eap-demo

Ce dépôt présente un exemple de personnalisation de JBoss EAP sous OpenShift en utilisation les fonctionnalités de source2image.

**NOTE:** Le driver JDBC driver d'Oracle n'est pas inclut dans ce dépôt.  [Téléchargement du driver JDBC](http://www.oracle.com/technetwork/database/features/jdbc/jdbc-ucp-122-3110062.html)

Le dépot est structuré de la manière suivante:
Répertoire `demo` contenant l'application a déployer.
Le répertoire `demo` comprends les sous-répertoires suivants:

- répertoire `.s2i` qui inclut un [fichier](https://github.com/masauve/eap-demo/blob/main/demo/.s2i/environment) `environment`. Ce fichier indique au processus de build de JBoss d'utiliser des extensions et modules additionnels: `CUSTOM_INSTALL_DIRECTORIES=extensions`. 

- un [répertoire](https://github.com/masauve/eap-demo/tree/main/demo/extensions) `extensions`  qui contient:
  - La [structure de modules nécessaires pour JBoss](https://github.com/masauve/eap-demo/tree/main/demo/extensions/modules/com/oracle/main) 

  - Un [fichier](https://github.com/masauve/eap-demo/blob/main/demo/extensions/drivers.env)`drivers.env` pour configurer les paramêtres de connectivité.   Voir [la documentation Red Hat](https://access.redhat.com/documentation/en-us/red_hat_jboss_enterprise_application_platform/7.1/html-single/red_hat_jboss_enterprise_application_platform_for_openshift/#S2I-Artifacts) pour des détails additionnels sur ce fichier.
  - un fichier `install.sh` qui est exécuté pendant le processus de construction d'Openshift s2i. Ce script s'occupe de l'installation du pilote Oracle JDBC en tant que module dans l'image JBoss EAP. (ajout de fichiers à l'image et mise à jour de standalone-openshift.xml pour inclure la configuration du pilote)

- un [répertoire](https://github.com/masauve/eap-demo/tree/main/demo/configuration) `configuration` qui contient:
  - un fichier `datasources.env`  qui fournit toutes les spécificités de la source de données. Ces paramètres sont intégrés à la configuration JBoss EAP au moment du déploiement du pod. Plusieurs sources de données peuvent être fournies, bien que cet exemple n'en utilise qu'une. Voir la documentation [JBoss EAP for Openshift](https://access.redhat.com/documentation/en-us/red_hat_jboss_enterprise_application_platform/7.1/html-single/red_hat_jboss_enterprise_application_platform_for_openshift/#S2I-Artifacts) pour plus de détails.


# Pour déployer


Mettre à jour les versions de JBoss EAP dans votre environnement OpenShift:

```
for resource in \
  eap73-amq-persistent-s2i.json \
  eap73-amq-s2i.json \
  eap73-basic-s2i.json \
  eap73-https-s2i.json \
  eap73-image-stream.json \
  eap73-sso-s2i.json \
  eap73-starter-s2i.json \
  eap73-third-party-db-s2i.json \
  eap73-tx-recovery-s2i.json
do
  oc replace --force -f \
https://raw.githubusercontent.com/jboss-container-images/jboss-eap-7-openshift-image/eap73/templates/${resource}
done

```
