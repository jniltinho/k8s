# Kubernetes tools for EKS

docker build for AWS, it can be used as normal kubectl tool as well

### Installed tools

- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator) (latest version when run the build)
- [awscli](https://github.com/aws/aws-cli) (latest version when run the build)
- General tools, such as bash, curl

### Github Repo

https://github.com/alpine-docker/k8s


### Docker image tags

https://hub.docker.com/r/alpine/k8s/tags/

# Why we need it

Mostly it is used during CI/CD (continuous integration and continuous delivery) or as part of an automated build/deployment

# kubectl versions

You should check in file [.travis.yml](.travis.yml), it lists the kubectl version and used as image tags.

# Involve with developing and testing

If you want to build these images by yourself, please follow below commands.

```
export tag=1.13.12

bash ./build.sh
```
Then you need adjust the tag to other kubernetes version and run the build script again.
