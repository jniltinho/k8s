# Kubernetes CI/CD tools

docker build for AWS, it can be used as normal kubectl tool as well

### Installed tools

- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [yq](https://github.com/mikefarah/yq)
- [katafygio](https://github.com/bpineau/katafygio)
- [docker-compose](https://github.com/docker/compose)
- [fabric3](https://docs.fabfile.org/en/2.6/)
- [docker-slim](https://github.com/docker-slim/docker-slim)
- [doctl](https://docs.digitalocean.com/reference/doctl/)
- rsync
- General tools, such as bash, curl

### Github Repo

https://github.com/alpine-docker/k8s


### Docker image tags

https://github.com/jniltinho/k8s/pkgs/container/dind-alpine-k8s

# Why we need it

Mostly it is used during CI/CD (continuous integration and continuous delivery) or as part of an automated build/deployment

# Involve with developing and testing

If you want to build these images by yourself, please follow below commands.

```
git clone https://github.com/jniltinho/k8s.git
cd k8s
bash ./build.sh
```
Then you need adjust the tag to other kubernetes version and run the build script again.
