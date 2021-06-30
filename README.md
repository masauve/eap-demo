# eap-demo

Ce dépôt présente un exemple de personnalisation de JBoss EAP sous OpenShift en utilisation les fonctionnalités de source2image.

**NOTE:** Le driver JDBC driver d'Oracle n'est pas inclut dans ce dépôt.  [Téléchargement du driver JDBC](http://www.oracle.com/technetwork/database/features/jdbc/jdbc-ucp-122-3110062.html)

Le dépot est structuré de la manière suivante:
Répertoire `demo` contenant l'application a déployer.
Le répertoire `demo` comprends les sous-répertoires suivants:

- répertoire `.s2i` qui inclut un [fichier](https://github.com/masauve/eap-demo/blob/main/demo/.s2i/environment) `environment`. Ce fichier indique au processus de build de JBoss d'utiliser des extensions et modules additionnels: `CUSTOM_INSTALL_DIRECTORIES=extensions`. 

- un [répertoire](https://github.com/masauve/eap-demo/tree/main/demo/extensions) `extensions`  qui contient:
  - the necessary [module directory structure and module.xml](https://github.com/travisrogers05/eap-oracle-db/tree/master/extensions/modules/com/oracle/main) file for the Oracle JDBC driver, as well as the Oracle JDBC driver file.  The Oracle JDBC driver must be [downloaded from Oracle](http://www.oracle.com/technetwork/database/features/jdbc/jdbc-ucp-122-3110062.html).
  - A `drivers.env` [file](https://github.com/travisrogers05/eap-oracle-db/blob/master/extensions/drivers.env) that contains driver specific details.  This example includes one driver, but multiple drivers can be included.  Refer to the [JBoss EAP for Openshift documentation](https://access.redhat.com/documentation/en-us/red_hat_jboss_enterprise_application_platform/7.1/html-single/red_hat_jboss_enterprise_application_platform_for_openshift/#S2I-Artifacts) for further details about the expected contents of this file.
  - An `install.sh` [file](https://github.com/travisrogers05/eap-oracle-db/blob/master/extensions/install.sh) that is executed during the Openshift s2i build process.  This script takes care of installing the Oracle JDBC driver as a module into the JBoss EAP image.  (adding files to the image and updating the standalone-openshift.xml to include the driver config)
- A `configuration` [directory](https://github.com/travisrogers05/eap-oracle-db/blob/master/configuration) that contains
  - A `datasources.env` [file](https://github.com/travisrogers05/eap-oracle-db/blob/master/configuration/datasources.env) that provides all the specifics for the datasource.  These settings are incorporated into the JBoss EAP configuration at pod deploy time.  Multiple datasources can be provided, although this example uses only one.  Refer to the [JBoss EAP for Openshift documentation](https://access.redhat.com/documentation/en-us/red_hat_jboss_enterprise_application_platform/7.1/html-single/red_hat_jboss_enterprise_application_platform_for_openshift/#S2I-Artifacts) for further details about the expected contents of this file.


## How it works

An Openshift build process clones this git repo into a build pod that performs a maven build of the example servlet.  The example servlet artifact and Oracle JDBC driver are copied into the image during the build.  The JBoss EAP standalone-openshift.xml that is provide in the JBoss EAP for Openshift image is updated to include the Oracle JDBC driver configuration.  The Openshift build process produces a container image to be used in application pods.

When the resulting container image is used to produce an application pod, the pod is configured at deploy time to include datasource settings provided by the `datasources.env` [file](https://github.com/travisrogers05/eap-oracle-db/blob/master/configuration/datasources.env).

# eap-demo
