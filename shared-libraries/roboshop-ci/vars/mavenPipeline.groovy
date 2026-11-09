def call(Map config = [:]) {

    // Validate configuration before starting
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

        agent any

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
            DOCKERFILE_PATH = "${config.dockerfile ?: 'Dockerfile'}"

            AWS_REGION = "${config.awsRegion}"
            ECR_REPOSITORY = "${config.ecrRepository}"

            AWS_CREDENTIAL_ID = "${awsCredentialId}"
            NOTIFICATION_EMAIL = "${config.notificationEmail ?: ''}"
        }

        stages {

            stage('Checkout') {
                steps {
                    checkoutCode()
                }
            }

            stage('Initialize Pipeline') {
                steps {
                    initializePipeline()
                }
            }

            stage('Setup Java and Maven') {
                steps {
                    setupJavaMaven()
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

            stage('Dependency Scan') {
                steps {
                    dependencyScan()
                }
            }

            stage('Package Application') {
                steps {
                    packageApplication()
                }
            }

            stage('Docker Build') {
                steps {
                    dockerBuild()
                }
            }

            stage('Trivy Image Scan') {
                steps {
                    trivyScan()
                }
            }

            stage('Push to ECR') {
                steps {
                    pushToECR()
                }
            }

            stage('Generate Build Metadata') {
                steps {
                    generateBuildMetadata()
                }
            }

        }

        post {
            always {
                script {
                    notifyPipeline()
                }
            }
        }
    }
}