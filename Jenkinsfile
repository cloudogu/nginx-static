#!groovy

@Library(['github.com/cloudogu/dogu-build-lib@v1.6.0', 'github.com/cloudogu/ces-build-lib@1.59.0'])
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
repositoryName = "nginx-static"
project = "github.com/${repositoryOwner}/${repositoryName}"

// Configuration of branches
productionReleaseBranch = "main"
developmentBranch = "develop"
currentBranch = "${env.BRANCH_NAME}"

// Go version used fpr the makefiles to generate k8s resources
goVersion = "1.18"

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

        stage('Lint') {
            lintDockerfile()
        }

        stage('Shellcheck') {
            shellCheck('./resources/startup.sh')
        }

        stage('Shell tests') {
            executeShellTests()
        }

        stage('Generate k8s Resources') {
            docker.image("golang:${goVersion}")
                    .mountJenkinsUser()
                    .inside("--volume ${WORKSPACE}:/workdir -w /workdir") {
                        make 'k8s-create-temporary-resource'
                    }
            archiveArtifacts 'target/make/k8s/*.yaml'
        }

        K3d k3d = new K3d(this, "${WORKSPACE}", "${WORKSPACE}/k3d", env.PATH)

        try {
            String doguVersion = getDoguVersion(false)
            GString sourceDeploymentYaml = "target/make/k8s/${repositoryName}_${doguVersion}.yaml"

            stage('Set up k3d cluster') {
                k3d.startK3d()
            }

            String imageName
            stage('Build & Push Image') {
                // pull protected base image
                docker.withRegistry('https://registry.cloudogu.com/', "cesmarvin-setup") {
                    String currentBaseImage = sh(
                        script: 'grep -m1 "registry.cloudogu.com/official/base" Dockerfile | sed "s|FROM ||g" | sed "s| as builder||g"',
                        returnStdout: true
                    )
                    currentBaseImage = currentBaseImage.trim()
                    image = docker.image(currentBaseImage)
                    image.pull()
                }

                String namespace = getDoguNamespace()
                imageName = k3d.buildAndPushToLocalRegistry("${namespace}/${repositoryName}", doguVersion)
            }

            stage('Setup') {
                k3d.setup("v0.8.1", [
                        dependencies: ["official/postfix", "k8s/nginx-ingress"],
                        defaultDogu : ""
                ])
            }

            stage('Deploy Dogu') {
                k3d.installDogu(repositoryName, imageName, sourceDeploymentYaml)
            }

            stage('Wait for Ready Rollout') {
                k3d.waitForDeploymentRollout(repositoryName, 300, 5)
            }

            stage('Test static content') {
                testStaticContentAccess(k3d)
            }

            stageAutomaticRelease()
        } catch(Exception e) {
            k3d.collectAndArchiveLogs()
            throw e
        }finally {
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

void stageAutomaticRelease() {
    if (gitflow.isReleaseBranch()) {
        String releaseVersion = getDoguVersion(true)
        String dockerReleaseVersion = getDoguVersion(false)
        String namespace = getDoguNamespace()
        String credentials = 'cesmarvin-setup'
        def dockerImage

        stage('Build & Push Image') {
            dockerImage = docker.build("${namespace}/${repositoryName}:${dockerReleaseVersion}")
            docker.withRegistry('https://registry.cloudogu.com/', credentials) {
                dockerImage.push("${dockerReleaseVersion}")
            }
        }

        stage('Push dogu.json') {
            String doguJson = sh(script: "cat dogu.json", returnStdout: true)
            HttpClient httpClient = new HttpClient(this, credentials)
            result = httpClient.put("https://dogu.cloudogu.com/api/v2/dogus/${namespace}/${repositoryName}", "application/json", doguJson)
            status = result["httpCode"]
            body = result["body"]

            if ((status as Integer) >= 400) {
                echo "Error pushing dogu.json"
                echo "${body}"
                sh "exit 1"
            }
        }

        stage('Finish Release') {
            gitflow.finishRelease(releaseVersion, productionReleaseBranch)
        }

        stage('Regenerate resources for release') {
            new Docker(this)
                    .image("golang:${goVersion}")
                    .mountJenkinsUser()
                    .inside("--volume ${WORKSPACE}:/go/src/${project} -w /go/src/${project}")
                            {
                                make 'k8s-create-temporary-resource'
                            }
        }

        stage('Add Github-Release') {
            String doguVersion = getDoguVersion(false)
            GString doguYaml = "target/make/k8s/${repositoryName}_${doguVersion}.yaml"
            releaseId = github.createReleaseWithChangelog(releaseVersion, changelog, productionReleaseBranch)
            github.addReleaseAsset("${releaseId}", "${doguYaml}")
        }
    }
}

String getDoguVersion(boolean withVersionPrefix) {
    def doguJson = this.readJSON file: 'dogu.json'
    String version = doguJson.Version

    if (withVersionPrefix) {
        return "v" + version
    } else {
        return version
    }
}

String getDoguNamespace() {
    def doguJson = this.readJSON file: 'dogu.json'
    return doguJson.Name.split("/")[0]
}

void make(String makeArgs) {
    sh "make ${makeArgs}"
}

def executeShellTests() {
    def bats_base_image = "bats/bats"
    def bats_custom_image = "cloudogu/bats"
    def bats_tag = "1.2.1"

    def batsImage = docker.build("${bats_custom_image}:${bats_tag}", "--build-arg=BATS_BASE_IMAGE=${bats_base_image} --build-arg=BATS_TAG=${bats_tag} ./build/make/bats")
    try {
        sh "mkdir -p target"

        batsContainer = batsImage.inside("--entrypoint='' -v ${WORKSPACE}:/workspace") {
            sh "make unit-test-shell-ci"
        }
    } finally {
        junit allowEmptyResults: true, testResults: 'target/shell_test_reports/*.xml'
    }
}