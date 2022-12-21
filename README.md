<img  align="right" width="150" style="float: right;" src="https://www.upm.es/sfs/Rectorado/Gabinete%20del%20Rector/Logos/UPM/CEI/LOGOTIPO%20leyenda%20color%20JPG%20p.png">

<br/>

# RDSV - PRÁCTICA FINAL - Grupo 6

Repositorio de la práctica final de la asignatura RDSV - Curso 2022/2023.<br/>
Versión: 21 de diciembre de 2022.

## Autores ✒️

* **Adrián Callejas Zurita** - [acallejasz](https://github.com/acallejasz)
* **Javier Velázquez Martínez** - [jvelazquezm](https://github.com/jvelazquezm)
* **Sara Docasar Moreno** - [saradocasar](https://github.com/saradocasar)

## Descripción del proyecto 📋

Esta sección trata de poner una visión general sobre el contenido y desarrollo seguido en la realización de la práctica. En primer lugar, hay que tener claro que servicio de red objeto de estudio es el servicio residencial de acceso a Internet, donde el router residencial se sustituye por un ‘Bridged Residential Gateway (BRG)’ que realiza la conmutación de nivel 2 del tráfico de los usuarios entre la red residencial y la central local. El resto de las funciones se realizan en la central local aplicando técnicas de NFV, creando un servicio de CPE virtual (vCPE) gestionado mediante la plataforma de orquestación. Para implementarlo se ha utilizado la RDSV2022-v1.ova, que virtualiza RDSV-K8S y RDSV-OSM, que nos permite utilizar el paquete microk8s, la herramienta VNX, Open vSwitch (ovs) y el entorno OSM, al que se accede gráficamente.

De este modo, el uso de las diferentes tecnologías y conectividad ha sido el siguiente: la tecnología VXLAN se ha usado para enviar encapsuladas en datagramas UDP las tramas de nivel 2 que viajan entre brg1, KNF:access y KNF:cpe. Para permitir esta comunicación, tanto el brg1 como KNF:access tienen interfaces en AccessNet1, configuradas con direcciones IP del prefijo 10.255.0.0/24. La asignación de direcciones IP a KNF:access y KNF:cpe en la red que las interconecta está gestionada por OSM y k8s, de manera que se asignan dinámicamente.
Antes de comenzar con la práctica se ha realizado el proceso de instalación, con las pruebas de conectividad necesarias, así como la descarga del repositorio de la práctica y el compartido y el arranque y configuración de los escenarios VNX. Tras esto, se ha definido el clúster k8s en OSM, donde se a almacenado una variable de entorno con el valor del namespace que va a utilizar OSM en el clúster para desplegar los pods de los servicios de red. 

Finalmente, durante la realización de la práctica, se han llevado a cabo la realización de una serie de mejoras mínimas y opcionales que se incluyen a continuación. También se indica como esta compuesto el repositorio y la funcionalidad de cada parte.

### Requisitos mínimos ⚙️

- Sustituir el switch de KNF:access por un conmutador controlado por OpenFlow.
- Conectividad IPv4 desde la red residencial hacia Internet. Uso de doble NAT: en KNF:cpe y en isp1.
- Activar la captura de tráfico ARP mediante “arpwatch”.
- Gestión de la calidad de servicio en la red de acceso mediante la API REST de Ryu controlando KNF:access, para limitar el ancho de banda de bajada hacia la red residencial. Debe ser independiente de la dirección IP asignada por DHCP a hX1 y hX2.
- Despliegue para dos redes residenciales.
- Todo automatizado mediante OSM y scripts, incluyendo el on-boarding de NS/VNFs y la instanciación de NS mediante línea.
de comandos

### Requisitos opcionales ⚙️

- Utilizar un repositorio privado de imágenes Docker: MicroK8s.
- Sustituir el switch de brgX por un conmutador controlado por OpenFlow desde el Ryu, incluyendo la gestión de la calidad de servicio desde el Ryu instalado en KNF:access y controlandolo para limitar el ancho de banda de subida desde la red residencial. Debe ser independiente de la dirección IP asignada por DHCP a hX1 y hX2.
- Instalar la funcionalidad arpwatch en un tercer contenedor, modificando los descriptores de OSM y creando un nuevo Helm char.

## Estructura del repositorio 🧱

- Directorio **helm**: Contiene los helm charts: cpe, access y arpwatch, con la imagen del repositorio modificada. Sobre los ya proporcionados, se ha añadido uno nuevo para el requisito opcional de arpwatch en un nuevo contenedor, con todos los archivos y configuración necesaria (values.yaml, chart.yaml y templates).
- Directorio **img**: Contiene los ficheros necesarios para construir la imagen de Docker y poder subirla al DockerHub, así como el propio Dockerfile con el que se compila la imagen, con los cambios pertinentes para cumplir con los requisitos presentados.
- Directorio **pck**: Contiene las descripciones de las funciones de red de cada uno de los helm charts (cpe, access y arpwatch), del servicio de red de la instancia de renes (modificado para el arpwatch) y los archivos comprimidos que se añadirán a OSM.
- Directorio **vnx**: Contiene las especificaciones xml para desplegar las redes residenciales y el servidor en la máquina de RDSV-K8s mediante vnx, con las modificaciones realizadas para cumplir con los requisitos.
- Archivos **.tgz**: Necesarios para que OSM los descargue al indicar la dirección de nuestro repositorio Helm, junto con el index.yaml configurado en las pages de este repositorio, tras haberlos empaquetado y actualizado previamente con Helm.
- Archivos **.sh**: Necesarios para desplegar, configurar y destruir en ambas máquinas virtuales el escenario completo con todas las mejoras realizadas y de manera automatizada.

## Arquitectura del escenario 🛠️	

A continuación se presenta el escenario final que se ha desplegado, que cuenta con los siguientes componentes:

- Cuatro sistemas finales hX1 y hX2 en casa del usuario, conectados al brgX que, a través de la red de acceso AccessNet se conectan a su vez a la central local, donde el servicio de red residencial se ofrece por dos VNF implementadas mediante Kubernetes.
- Una KNF:access, que se conecta a la red de acceso y permitiría clasificar el tráfico e implementar QoS en el acceso del usuario a la red.
- Una KNF:arpwatch,
- Una KNF:vcpe, que integrará las funciones de servidor DHCP, NAT y reenvío de IP.

![Escenario](https://github.com/jvelazquezm/repo-rdsv/blob/main/escenario/escenario.jpg)

Además, hay que tener en cuenta que:

- Se utiliza la tecnología VXLAN para enviar encapsuladas en datagramas UDP las tramas de nivel 2 que viajan entre brg1, KNF:access, KNF:arpwatch y KNF:cpe. 
- La asignación de direcciones IP a las KNF's está gestionada por OSM y k8s, de manera que se asignan dinámicamente al instanciar las KNFs.

## Despliegue del entorno 🚀

A continuación, se presentan los pasos a seguir para inicializar ambas redes residenciales virtualizadas con OSM con los requisitos mínimos y opcionales que han sido realizados.

### Pasos previos 🔧

- Iniciar las dos máquinas virtuales en el laboratorio o en el ordenador personal: `RDSV-K8S | RDSV-OSM`
- Acceder al directorio compartido y clonar el repositorio en ambas máquinas con el comando:
```
cd shared
git clone https://github.com/jvelazquezm/repo-rdsv.git
```
- Comprobar que scripts que se van a ejecutar cuentan con permisos de ejecución. En caso contrario, ejecutar:
```
chmod +x <nombre_script.sh>
```
- Modificar las imágenes utilizadas por VNX para que incluyan iperf3 para las pruebas de QoS. Para ello ejecutar el siguiente comando, hacer login con root/xxxx e instalar los paquetes deseados. Finalmente, parar el contenedor con `halt -p`.
```
vnx --modify-rootfs /usr/share/vnx/filesystems/vnx_rootfs_lxc_ubuntu64-20.04-v025-vnxlab/
```
- En la máquina de OSM compruebe que tiene configurado un cluster de k8s mediante el comando:
```
osm k8scluster-list
```

### Despliegue en RDSV-K8S 🏹

- Entramos dentro de la carpeta del repositorio mediante el comando:
```
cd repo-rsdv
```
- Ejecutamos el script de creación del escenario, init_k8s.sh:
```
./init_k8s.sh
```

### Despliegue en RDSV-OSM🏹

- Entramos dentro de la carpeta del repositorio mediante el comando:
```
cd repo-rsdv
```
- Ejecutamos el script de creación del escenario, init_osm.sh, con el formato indicado, para que exporte bien las variables:
```
. init_osm.sh
```
- Ejecutamos el script de creación de las instancias de renes de las dos redes residenciales, osm_renes_all.sh, pasandole la variable indicada:
```
./osm_renes_all.sh $OSMNS
```
- En este punto debemos esperar a que el servidor DHCP asigne a los hosts la ip. Para comprobar que se ha realizado, en la máquina RDSV-K8S, en la terminal de cada uno de ellos, ejecutamos:
```
ifconfig
```
- Ejecutamos el script de configuración de la QoS descendente y ascendente para las dos redes residenciales, apply_qos_all.sh.
```
./apply_qos_all.sh $OSMNS
```

## Pruebas de conectividad, calidad de servicio y arpwatch

- Para probar la conectividad IPv4 desde la red residencial hacia Internet realizamos el siguiente ping desde cada uno los hosts, en la máquina RDSV-K8S:
```
ping 8.8.8.8
```
- Para probar la calidad de servicio, se hace uso de la herramienta iperf3. Para ello, se realizan pruebas desde diversas máquinas y debemos tener en cuenta que se debe cumplir lo siguiente: 
    - Para la red residencial: 12 Mbps de bajada (y 6 Mbps de subida)
    - Para hX1: 8 Mbps mínimo de bajada (y 4 Mbps mínimo de subida)
    - Para hX2: 4 Mbps máximo de bajada (y 2 Mbps máximo de subida)
```

```
- Para probar la funcionalidad del arpwatch, comprobamos que el registro de las MACs de la red residencial. Para ello, debemos realizar:
```
kubectl exec -n $OSMNS $VARP -- /bin/bash
cat /etc/default/arpwatch/brint.dat
cat /etc/default/arpwatch/eth0.dat
```

## Posibles errores a tener en cuenta

- Cuando se ejecute el script init_osm.sh, es posible que la instacia de renes no se cree bien la primera vez. Esto se debe a errores de la máquina virtual con el software OSM que tiene instalado. Basta con destruir el escenario con el script destroy_osm.sh y volver a ejecutar el init_osm.sh

- Nunca deben iniciarse los scripts de aplicar QoS sin que se hayan asignado las IPs a los hosts de las redes residenciales, ya que esto induciría a error. Siempre comprobarlo antes de ejecutar.

## Destrucción del entorno 💣

### RDSV-K8S 

- Ejecutamos el script de creación del escenario, destroy_k8s.sh:
```
./destroy_k8s.sh
```

### RDSV-OSM 

- Ejecutamos el script de creación del escenario, destroy_osm.sh:
```
./destroy_osm.sh
```
