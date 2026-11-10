
def call(Map config = [:]) {

    // Validate mandatory configuration
    [
        'project',
        'service',
        'appRepoUrl',
        'appBranch',
        'ecrRepository',
        'awsRegion'
    ].each { key ->
        if (!config[key]) {
            error "Missing mandatory configuration: ${key}"
        }
    }

    def awsCredentialId = "aws-creds-${config.project}"

    pipeline {

        agent {
            label'AGENT-1'
        }

        options {
            timestamps()
            disableConcurrentBuilds()
            buildDiscarder(logRotator(
                numToKeepStr: '20'
            ))
        }

        environment {
            PROJECT = "${config.project}"
            SERVICE_NAME = "${config.service}"

            APP_REPO_URL = "${config.appRepoUrl}"
            APP_BRANCH = "${config.appBranch}"

            POM_PATH = "${config.pomPath ?: 'pom.xml'}"

            AWS_REGION = "${config.awsRegion}"
            ECR_REPOSITORY = "${config.ecrRepository}"

            AWS_CREDENTIAL_ID = "${awsCredentialId}"
        }

        stages {

            stage('Checkout') {
                steps {
                    checkoutCode()
                }
            }
            stage('Setup Java and Maven') {
                steps {
                    setupJavaMaven()
                }
            }

            stage('Initialize Pipeline') {
                steps {
                    initializePipeline()
                }
            }

            

            stage('Maven Clean and Compile') {
                steps {
                    mavenBuild()
                }
            }

            stage('Unit Tests') {
                steps {
                    unitTests()
                }
            }

            stage('SonarQube Analysis') {
                steps {
                    sonarqubeAnalysis()
                }
            }

            stage('Quality Gate') {
                steps {
                    qualityGate()
                }
            }

            stage('Package Application') {
                steps {
                    packageApplication()
                }
            }
        }
    }
}
