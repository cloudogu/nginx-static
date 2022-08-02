#!groovy

@Library(['github.com/cloudogu/dogu-build-lib@v1.6.0', 'github.com/cloudogu/ces-build-lib@1.55.0'])
import com.cloudogu.ces.cesbuildlib.*
import com.cloudogu.ces.dogubuildlib.*

// Creating necessary git objects, object cannot be named 'git' as this conflicts with the method named 'git' from the library
gitWrapper = new Git(this, "cesmarvin")
gitWrapper.committerName = 'cesmarvin'
gitWrapper.committerEmail = 'cesmarvin@cloudogu.com'
gitflow = new GitFlow(this, gitWrapper)
github = new GitHub(this, gitWrapper)
changelog = new Changelog(this)
Docker docker = new Docker(this)

// Configuration of repository
repositoryOwner = "cloudogu"
repositoryName = "k8s-static-webserver"
project = "github.com/${repositoryOwner}/${repositoryName}"

// Configuration of branches
productionReleaseBranch = "main"
developmentBranch = "develop"
currentBranch = "${env.BRANCH_NAME}"

node('docker') {
    timestamps {
        properties([
                // Keep only the last x builds to preserve space
                buildDiscarder(logRotator(numToKeepStr: '10')),
                // Don't run concurrent builds for a branch, because they use the same workspace directory
                disableConcurrentBuilds(),
        ])

        stage('Checkout') {
            checkout scm
            make 'clean'
        }

        stage('Lint - Dockerfile') {
            lintDockerfile()
        }

        stage("Lint - k8s Resources") {
            stageLintK8SResources()
        }

        K3d k3d = new K3d(this, "${WORKSPACE}", "${WORKSPACE}/k3d", env.PATH)
        try {
            stage('Set up k3d cluster') {
                k3d.startK3d()
            }

            def repositoryNameImage
            stage('Build & Push Image') {
                def makefile = new Makefile(this)
                String version = makefile.getVersion()
                repositoryNameImage=k3d.buildAndPushToLocalRegistry("cloudogu/${repositoryName}", version)
            }

            stage('Setup') {
                k3d.setup("v0.6.0", [
                        dependencies: ["official/postfix", "official/plantuml", "k8s/nginx-ingress"],
                        defaultDogu : "plantuml"
                ])
            }

            stage('Deploy') {
                def sourceDeploymentYaml="k8s/${repositoryName}.yaml"
                stage('Update development resources') {
                    docker.image('mikefarah/yq:4.22.1')
                            .mountJenkinsUser()
                            .inside("--volume ${WORKSPACE}:/workdir -w /workdir") {
                                sh "yq -i '(select(.kind == \"Deployment\").spec.template.spec.containers[]|select(.name == \"${repositoryName}\")).image=\"${repositoryNameImage}\"' ${sourceDeploymentYaml}"
                    }
                }

                k3d.kubectl("apply -f ${sourceDeploymentYaml}")
            }


            stage('Wait for Ready Rollout') {
                k3d.waitForDeploymentRollout(repositoryName, 300, 5)
            }

            stage('Test static content') {
                testStaticContentAccess(k3d)
            }

            stageAutomaticRelease()
        } finally {
            stage('Remove k3d cluster') {
                k3d.deleteK3d()
            }
        }
    }
}


/**
 * Checks whether the static content is accessible and also the correct content.
 */
void testStaticContentAccess(K3d k3d) {
    k3d.waitForDeploymentRollout("nginx-ingress", 300, 5)

    // determine free port with python
    String port = sh(script: 'echo -n $(python3 -c \'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()\');', returnStdout: true)

    // the process is automatically terminated when canceling/terminating the build
    k3d.kubectl("port-forward service/nginx-ingress ${port}:443 &")

    sh "sleep 5"

    String errorPage = sh(
        script: "curl -L --insecure https://127.0.0.1:${port}/errors/404.html",
        returnStdout: true
    )

    if (!errorPage.contains("/errors/css/errors.css")) {
        sh "echo 404 page does not contain ces.css..."
        sh "exit 1"
    }

    if (!errorPage.contains("<script type=\"text/javascript\" src=\"/warp/add-warp-menu.js\"></script>")) {
        sh "echo 404 page does not contain warp menu script..."
        sh "exit 1"
    }

    String warpMenuScript = sh(
        script: "curl -L --insecure https://127.0.0.1:${port}/warp/add-warp-menu.js",
        returnStdout: true
    )

    if (!warpMenuScript.contains("addWarpMenu()")) {
        sh "echo warp menu script seems wrong..."
        sh "exit 1"
    }
}

void stageLintK8SResources() {
    String kubevalImage = "cytopia/kubeval:0.13"
    docker
            .image(kubevalImage)
            .inside("-v ${WORKSPACE}/k8s:/data -t --entrypoint=")
                    {
                        sh "kubeval /data/${repositoryName}.yaml --ignore-missing-schemas"
                    }
}

void stageAutomaticRelease() {
    if (gitflow.isReleaseBranch()) {
        String releaseVersion = gitWrapper.getSimpleBranchName()
        Makefile makefile = new Makefile(this)
        String version = makefile.getVersion()

        stage('Build & Push Image') {
            def dockerImage = docker.build("cloudogu/${repositoryName}:${version}")

            docker.withRegistry('https://registry.hub.docker.com/', 'dockerHubCredentials') {
                dockerImage.push("${version}")
            }
        }

        stage('Finish Release') {
            gitflow.finishRelease(releaseVersion, productionReleaseBranch)
        }

        stage('Regenerate resources for release') {
            make 'k8s-create-temporary-resource'
        }

        stage('Add Github-Release') {
            GString targetOperatorResourceYaml = "target/make/k8s/${repositoryName}_${version}.yaml"
            releaseId = github.createReleaseWithChangelog(releaseVersion, changelog, productionReleaseBranch)
            github.addReleaseAsset("${releaseId}", "${targetOperatorResourceYaml}")
        }

        stage('Add Github-Release') {
            releaseId = github.createReleaseWithChangelog(releaseVersion, changelog, productionReleaseBranch)
        }
    }
}

void make(String makeArgs) {
    sh "make ${makeArgs}"
}