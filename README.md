# Configuration

Je me suis servi de l'installation Kubernetes de mon Docker Desktop pour faire tourner le projet en local. Les images ont été build depuis les dockerfiles dans les repo api et db fournis. Le fichier init.sql a été légèrement retouché pour coller à mes configurations .yaml.


Voici mes réponses aux questions :

__


# Volume et persistance

## Quel est le rôle d’un volume dans un déploiement Kubernetes ?

Un volume dans Kubernetes permet de fournir un espace de stockage persistant ou partagé à un ou plusieurs conteneurs d’un pod.  
Contrairement au système de fichiers éphémère d’un conteneur, un volume permet de conserver les données indépendamment du cycle de vie du conteneur.

Dans le cas d’une base de données (comme MySQL), le volume est indispensable pour garantir que les données ne soient pas perdues lors du redémarrage ou du remplacement d’un pod.

---

## Que signifie la mention `storageClassName` dans un PVC, et que peut-elle impliquer côté cloud ?

La propriété `storageClassName` dans un `PersistentVolumeClaim` indique quelle *StorageClass* doit être utilisée pour provisionner le volume.

Une `StorageClass` définit :
- le type de stockage (SSD, HDD, réseau, local, etc.)
- le fournisseur (ex. AWS EBS, GCP Persistent Disk, Azure Disk)
- les paramètres de performance et de réplication

Dans un environnement cloud, cela peut impliquer :
- la création automatique d’un disque managé
- des coûts supplémentaires selon le type de stockage
- des contraintes de zone ou de région

En local (ex. Docker Desktop), une StorageClass par défaut est souvent utilisée automatiquement.

---

## Que se passe-t-il si le pod MySQL disparaît ?

Si le pod MySQL disparaît (crash, redéploiement, mise à jour) :
- le pod est recréé automatiquement par le StatefulSet
- le volume persistant reste intact
- le nouveau pod remonte le même volume

Les données ne sont donc **pas perdues**, tant que le `PersistentVolumeClaim` n’est pas supprimé.

C’est ce mécanisme qui permet à Kubernetes de garantir la persistance des données indépendamment des pods.

---

## Qu’est-ce qui relie un PersistentVolumeClaim à un volume physique ?

Le lien entre un `PersistentVolumeClaim` (PVC) et un volume physique est assuré par un `PersistentVolume` (PV).

- Le PVC exprime un besoin (taille, accès, classe de stockage)
- Le PV représente un volume réel (disque, NFS, stockage cloud)
- Kubernetes effectue un *binding* automatique entre les deux

Une fois liés, le PVC référence toujours le même volume physique jusqu’à sa suppression.

---

## Comment le cluster gère-t-il la création ou la suppression du stockage sous-jacent ?

Cela dépend de la StorageClass utilisée :
- En **provisionnement dynamique**, Kubernetes crée automatiquement le volume lorsqu’un PVC est créé.
- Lors de la suppression du PVC, la politique de rétention (`reclaimPolicy`) détermine le comportement :
  - `Delete` : le volume est supprimé
  - `Retain` : le volume est conservé manuellement
  - `Recycle` (obsolète)

Dans le cloud, cela correspond directement à la création ou la suppression de ressources de stockage facturables.

---

# Ingress et health probe

Cette section explique comment les services sont exposés et comment Kubernetes vérifie la disponibilité des applications.

## À quoi sert un Ingress dans Kubernetes ?

Un Ingress permet d’exposer des services HTTP/HTTPS vers l’extérieur du cluster en définissant :
- des règles de routage (chemins, domaines)
- la terminaison TLS
- le mapping entre URL et services internes

Il agit comme un point d’entrée unique pour les applications web.

---

## Quelle différence y a-t-il entre un Ingress et un Ingress Controller ?

- **Ingress** : ressource Kubernetes déclarative décrivant les règles de routage.
- **Ingress Controller** : composant logiciel qui interprète ces règles et les applique réellement.

Sans Ingress Controller (ex. NGINX, Traefik), une ressource Ingress n’a aucun effet.

---

## À quoi sert un health probe dans une architecture de déploiement ?

Les health probes permettent à Kubernetes de surveiller l’état d’une application.

On distingue principalement :
- **Liveness probe** : vérifie si l’application doit être redémarrée
- **Readiness probe** : vérifie si l’application est prête à recevoir du trafic

Ces mécanismes permettent une haute disponibilité et une gestion automatique des pannes.

---

## Quelle est la relation entre le chemin défini dans le probe et les routes réellement exposées par l’application ?

Le chemin défini dans un probe doit correspondre à une route HTTP **réellement exposée** par l’application.

Si l’endpoint :
- n’existe pas
- retourne un code différent de 200
- ou dépend d’un service indisponible

alors le probe échoue, et Kubernetes considère l’application comme non prête ou défaillante.

---

## Comment mettre en place un chemin de préfixe (ex. `/votre_namespace`) dans l’Ingress, et quelle configuration doit être ajustée pour que ce chemin soit correctement pris en compte par l’application ?

Dans l’Ingress, un préfixe peut être défini via une règle de chemin :

```yaml
path: /votre_namespace
pathType: Prefix 
```

Deux approches sont possibles :

1. **Rewrite côté Ingress**  
   Le contrôleur d’Ingress peut réécrire l’URL avant de transmettre la requête au service (via des annotations spécifiques, par exemple avec NGINX).  
   Cela permet à l’application de continuer à exposer ses routes sans préfixe, tout en étant accessible via un chemin externe différent.

2. **Adaptation de l’application**  
   L’application peut être configurée pour exposer ses routes directement avec le préfixe défini (par exemple `/votre_namespace/health`, `/votre_namespace/clients`, etc.).

Dans tous les cas, la configuration de l’Ingress et celle de l’application doivent être cohérentes.  
Si le chemin attendu par l’Ingress ne correspond pas aux routes réellement exposées par l’application, les requêtes échoueront (404 ou échec des probes).

---

## Comment le contrôleur d’Ingress décide-t-il si un service est “sain” ou non ?

Le contrôleur d’Ingress ne teste pas directement l’application. Il s’appuie sur l’état des ressources Kubernetes sous-jacentes :

- le **Service**, qui référence un ensemble de pods
- l’état **Ready** des pods exposés par ce service

Cet état Ready est déterminé par les `readinessProbes` définies dans les pods.  
Seuls les pods considérés comme prêts sont inclus dans le routage du trafic.

Si aucun pod n’est marqué comme Ready, le contrôleur d’Ingress cesse de rediriger le trafic vers le service, évitant ainsi d’envoyer des requêtes vers une application non fonctionnelle.
