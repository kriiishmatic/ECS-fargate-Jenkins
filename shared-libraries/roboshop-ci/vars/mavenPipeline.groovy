
import groovy.json.JsonSlurperClassic

def captureStageFailure(String stageName, Closure body) {

    env.CURRENT_STAGE = stageName

    try {
        body.call()
    } catch (err) {

        env.FAILURE_MESSAGE = err.getMessage() ?: err.toString()

        throw err
    }
}

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
            label 'AGENT-1'
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

            GITHUB_METADATA_BUCKET = "${config.githubMetadataBucket ?: 'project-k-github-metadata'}"
            GITHUB_REPOSITORY = "${config.githubRepository ?: 'kriiishmatic/roboshop-shipping-ci'}"

            GITHUB_PUSHER_LOGIN = ''
            GITHUB_PUSHER_ID = ''
        }

        stages {

            stage('Notify Build Started') {
                steps {
                    script {
                        notifyPipeline(
                            status: 'CI STARTED',
                            message: """
                            Shipping CI build has started.
                            Service: ${env.SERVICE_NAME}
                            Branch: ${env.BRANCH_NAME ?: env.APP_BRANCH}
                            """
                        )
                    }
                }
            }

            stage('Checkout') {
                steps {
                    script {
                        captureStageFailure('Checkout') {
                            checkoutCode()
                        }
                    }
                }
            }

            stage('Capture GitHub Push Metadata') {
                steps {
                    script {

                        def commitSha = sh(
                            script: 'git rev-parse HEAD',
                            returnStdout: true
                        ).trim()

                        env.GIT_COMMIT = commitSha
                        env.GIT_SHORT_COMMIT = commitSha.take(8)

                        echo "Checking GitHub push metadata for commit: ${commitSha}"

                        def metadataFound = false

                        // Retry briefly because the metadata receiver and
                        // multibranch pipeline can start at nearly the same time.
                        for (int attempt = 1; attempt <= 6; attempt++) {

                            try {

                                def metadataJson = sh(
                                    script: """
                                        aws s3 cp \
                                        s3://${env.GITHUB_METADATA_BUCKET}/shipping/${commitSha}.json \
                                        - \
                                        --region ${env.AWS_REGION} \
                                        2>/dev/null
                                    """,
                                    returnStdout: true
                                ).trim()

                                def metadata = new JsonSlurperClassic()
                                    .parseText(metadataJson)

                                def validCommit = metadata.commit_sha?.toString()
                                    ?.equalsIgnoreCase(commitSha)

                                def validRepository = metadata.repository?.toString()
                                    ?.equalsIgnoreCase(env.GITHUB_REPOSITORY)

                                def validEvent = metadata.event?.toString() == 'push'

                                if (validCommit && validRepository && validEvent &&
                                    metadata.pusher_login && metadata.pusher_id) {

                                    env.GITHUB_PUSHER_LOGIN =
                                        metadata.pusher_login.toString()

                                    env.GITHUB_PUSHER_ID =
                                        metadata.pusher_id.toString()

                                    metadataFound = true

                                    echo """
                                    GitHub push metadata retrieved successfully.
                                    Repository : ${metadata.repository}
                                    Commit     : ${commitSha}
                                    Pusher     : ${env.GITHUB_PUSHER_LOGIN}
                                    Pusher ID  : ${env.GITHUB_PUSHER_ID}
                                    """

                                    break

                                } else {

                                    echo 'GitHub metadata was found but did not pass validation.'
                                    break
                                }

                            } catch (err) {

                                echo "Metadata lookup attempt ${attempt}/6 failed."

                                if (attempt < 6) {
                                    sleep(time: 5, unit: 'SECONDS')
                                }
                            }
                        }

                        if (!metadataFound) {
                            echo """
                            WARNING: GitHub push metadata was not available.
                            Continuing CI with the normal Jenkins trigger information.
                            """
                        }
                    }
                }
            }

            stage('Setup Java and Maven') {
                steps {
                    script {
                        captureStageFailure('Setup Java and Maven') {
                            setupJavaMaven()
                        }
                    }
                }
            }

            stage('Initialize Pipeline') {
                steps {
                    script {
                        captureStageFailure('Initialize Pipeline') {
                            initializePipeline()
                        }
                    }
                }
            }

            stage('Maven Clean and Compile') {
                steps {
                    script {
                        captureStageFailure('Maven Clean and Compile') {
                            mavenBuild()
                        }
                    }
                }
            }

            stage('Unit Tests') {
                steps {
                    script {
                        captureStageFailure('Unit Tests') {
                            unitTests()
                        }
                    }
                }
            }

            stage('SonarQube Analysis') {
                steps {
                    script {
                        captureStageFailure('SonarQube Analysis') {
                            sonarqubeAnalysis()
                        }
                    }
                }
            }

            stage('Quality Gate') {
                steps {
                    script {
                        captureStageFailure('Quality Gate') {
                            qualityGate()
                        }
                    }
                }
            }

            stage('Package Application') {
                steps {
                    script {
                        captureStageFailure('Package Application') {
                            packageApplication()
                        }
                    }
                }
            }
        }

        post {

            success {
                script {
                    notifyPipeline(
                        status: 'CI SUCCESS',
                        message: """
                        All Shipping CI stages completed successfully.

                        Service: ${env.SERVICE_NAME}
                        Version: ${env.BUILD_VERSION ?: 'N/A'}

                        CI completed successfully. Ready for PR merge.
                        """
                    )
                }
            }

            failure {
                script {

                    def failedStage = env.CURRENT_STAGE ?: 'Unknown'
                    def failureDetails = env.FAILURE_MESSAGE ?:
                        'No exception details captured. Check Jenkins console output.'

                    notifyPipeline(
                        status: 'CI FAILED',
                        message: """
                        Shipping CI build failed.

                        Service: ${env.SERVICE_NAME}
                        Failed Stage: ${failedStage}
                        Error: ${failureDetails.take(500)}

                        Please check the Jenkins console output.
                        """
                    )
                }
            }

            aborted {
                script {
                    notifyPipeline(
                        status: 'CI ABORTED',
                        message: """
                        Shipping CI build was aborted.

                        Service: ${env.SERVICE_NAME}
                        """
                    )
                }
            }

            cleanup {
                echo 'Cleaning Jenkins workspace...'
                cleanWs()
            }
        }
    }
}
