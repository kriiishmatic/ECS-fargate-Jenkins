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

    // --------------------------------------------------
    // 1. Validate mandatory configuration
    // --------------------------------------------------

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

        // --------------------------------------------------
        // 2. Pipeline environment
        // --------------------------------------------------

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
        }

        // --------------------------------------------------
        // 3. Pipeline stages
        // --------------------------------------------------

        stages {

            // --------------------------------------------------
            // Checkout
            // --------------------------------------------------

            stage('Checkout') {
                steps {
                    script {
                        captureStageFailure('Checkout') {
                            checkoutCode()
                        }
                    }
                }
            }

            // --------------------------------------------------
            // Capture GitHub Push Metadata
            // --------------------------------------------------

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

                                if (!metadataJson) {
                                    throw new Exception('S3 returned empty metadata.')
                                }

                                def metadata = new JsonSlurperClassic()
                                    .parseText(metadataJson)

                                // Explicit map-key access for JSON fields.

                                def metadataCommit = metadata['commit_sha']?.toString()?.trim()
                                def metadataRepository = metadata['repository']?.toString()?.trim()
                                def metadataEvent = metadata['event']?.toString()?.trim()
                                def pusherLogin = metadata['pusher_login']?.toString()?.trim()
                                def pusherId = metadata['pusher_id']?.toString()?.trim()

                                echo "Metadata keys: ${metadata.keySet()}"
                                echo "Pusher login extracted: ${pusherLogin}"
                                echo "Pusher ID extracted: ${pusherId}"

                                // Validate metadata before accepting it.

                                def validCommit =
                                    metadataCommit &&
                                    metadataCommit.equalsIgnoreCase(commitSha)

                                def validRepository =
                                    metadataRepository &&
                                    metadataRepository.equalsIgnoreCase(env.GITHUB_REPOSITORY)

                                def validEvent = metadataEvent == 'push'

                                def validPusherLogin =
                                    pusherLogin &&
                                    !pusherLogin.equalsIgnoreCase('null')

                                def validPusherId =
                                    pusherId &&
                                    !pusherId.equalsIgnoreCase('null')

                                if (
                                    validCommit &&
                                    validRepository &&
                                    validEvent &&
                                    validPusherLogin &&
                                    validPusherId
                                ) {

                                    // Store values for later pipeline stages
                                    // and post-build Slack notifications.

                                    env.GITHUB_PUSHER_LOGIN = pusherLogin.toString()
                                    env.GITHUB_PUSHER_ID = pusherId.toString()

                                    metadataFound = true

                                    echo """
                                    GitHub push metadata retrieved successfully.

                                    Repository : ${metadataRepository}
                                    Commit     : ${commitSha}
                                    Pusher     : ${env.GITHUB_PUSHER_LOGIN}
                                    Pusher ID  : ${env.GITHUB_PUSHER_ID}
                                    """

                                    break

                                } else {

                                    echo """
                                    GitHub metadata validation failed.

                                    Commit valid     : ${validCommit}
                                    Repository valid : ${validRepository}
                                    Event valid      : ${validEvent}
                                    Pusher valid     : ${validPusherLogin}
                                    Pusher ID valid  : ${validPusherId}
                                    """

                                    break
                                }

                            } catch (err) {

                                echo "Metadata lookup attempt ${attempt}/6 failed: ${err.getMessage()}"

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

            // --------------------------------------------------
            // Capture Jenkins Trigger Identity
            // --------------------------------------------------

            stage('Capture Jenkins Trigger Identity') {
                steps {
                    script {

                        def causes = currentBuild.getBuildCauses()

                        def userCause = causes.find {
                            it['_class'] == 'hudson.model.Cause$UserIdCause'
                        }

                        def causeDescription = causes
                            .collect { it['shortDescription'] }
                            .findAll { it }
                            .join('; ')

                        if (userCause) {

                            env.JENKINS_TRIGGER_TYPE = 'Manual Jenkins Build'

                            env.JENKINS_TRIGGER_USER =
                                userCause['userName'] ?:
                                userCause['userId'] ?:
                                'Unknown Jenkins user'

                        } else if (env.GITHUB_PUSHER_LOGIN) {

                            env.JENKINS_TRIGGER_TYPE = 'GitHub Push Webhook'

                            env.JENKINS_TRIGGER_USER =
                                'Not applicable (webhook-triggered)'

                        } else {

                            env.JENKINS_TRIGGER_TYPE =
                                causeDescription ?: 'Automated trigger'

                            env.JENKINS_TRIGGER_USER = 'Not available'
                        }

                        env.JENKINS_TRIGGER_CAUSE =
                            causeDescription ?: 'Not available'

                        echo "Trigger type: ${env.JENKINS_TRIGGER_TYPE}"
                        echo "Jenkins user: ${env.JENKINS_TRIGGER_USER}"
                        echo "Trigger cause: ${env.JENKINS_TRIGGER_CAUSE}"
                    }
                }
            }

            // --------------------------------------------------
            // Notify Build Started
            // --------------------------------------------------

            stage('Notify Build Started') {
                steps {
                    script {
                        notifyPipeline(
                            status: 'CI STARTED',
                            message: """
                            Shipping CI build has started.

                            Service: ${env.SERVICE_NAME}
                            Branch: ${env.BRANCH_NAME ?: env.APP_BRANCH}
                            Commit: ${env.GIT_SHORT_COMMIT ?: 'Not available'}

                            Trigger Type: ${env.JENKINS_TRIGGER_TYPE ?: 'Not available'}
                            Jenkins User: ${env.JENKINS_TRIGGER_USER ?: 'Not available'}
                            Trigger Cause: ${env.JENKINS_TRIGGER_CAUSE ?: 'Not available'}

                            GitHub Pusher: ${env.GITHUB_PUSHER_LOGIN ?: 'Not available'}
                            GitHub User ID: ${env.GITHUB_PUSHER_ID ?: 'Not available'}
                            """
                        )
                    }
                }
            }

            // --------------------------------------------------
            // Setup Java and Maven
            // --------------------------------------------------

            stage('Setup Java and Maven') {
                steps {
                    script {
                        captureStageFailure('Setup Java and Maven') {
                            setupJavaMaven()
                        }
                    }
                }
            }

            // --------------------------------------------------
            // Initialize Pipeline
            // --------------------------------------------------

            stage('Initialize Pipeline') {
                steps {
                    script {
                        captureStageFailure('Initialize Pipeline') {
                            initializePipeline()
                        }
                    }
                }
            }

            // --------------------------------------------------
            // Maven Clean and Compile
            // --------------------------------------------------

            stage('Maven Clean and Compile') {
                steps {
                    script {
                        captureStageFailure('Maven Clean and Compile') {
                            mavenBuild()
                        }
                    }
                }
            }

            // --------------------------------------------------
            // Unit Tests
            // --------------------------------------------------

            stage('Unit Tests') {
                steps {
                    script {
                        captureStageFailure('Unit Tests') {
                            unitTests()
                        }
                    }
                }
                post {
                    always {
                        junit(
                            testResults: '**/target/surefire-reports/TEST-*.xml',
                            allowEmptyResults: true
                        )
                    }
                }
            }

            // --------------------------------------------------
            // SonarQube Analysis
            // --------------------------------------------------

            stage('SonarQube Analysis') {
                steps {
                    script {
                        captureStageFailure('SonarQube Analysis') {
                            sonarqubeAnalysis()
                        }
                    }
                }
            }

            // --------------------------------------------------
            // Quality Gate
            // --------------------------------------------------

            stage('Quality Gate') {
                steps {
                    script {
                        captureStageFailure('Quality Gate') {
                            qualityGate()
                        }
                    }
                }
            }

            // --------------------------------------------------
            // Package Application
            // --------------------------------------------------

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

        // --------------------------------------------------
        // 4. Post-build actions and notifications
        // --------------------------------------------------

        post {

            success {
                script {
                    notifyPipeline(
                        status: 'CI SUCCESS',
                        message: """
                        All Shipping CI stages completed successfully.

                        Service: ${env.SERVICE_NAME}
                        Version: ${env.BUILD_VERSION ?: 'N/A'}
                        Branch: ${env.BRANCH_NAME ?: env.APP_BRANCH}
                        Commit: ${env.GIT_SHORT_COMMIT ?: 'Not available'}

                        Trigger Type: ${env.JENKINS_TRIGGER_TYPE ?: 'Not available'}
                        Jenkins User: ${env.JENKINS_TRIGGER_USER ?: 'Not available'}
                        Trigger Cause: ${env.JENKINS_TRIGGER_CAUSE ?: 'Not available'}

                        GitHub Pusher: ${env.GITHUB_PUSHER_LOGIN ?: 'Not available'}
                        GitHub User ID: ${env.GITHUB_PUSHER_ID ?: 'Not available'}

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
                        Branch: ${env.BRANCH_NAME ?: env.APP_BRANCH}
                        Commit: ${env.GIT_SHORT_COMMIT ?: 'Not available'}

                        Failed Stage: ${failedStage}
                        Error: ${failureDetails.take(500)}

                        Trigger Type: ${env.JENKINS_TRIGGER_TYPE ?: 'Not available'}
                        Jenkins User: ${env.JENKINS_TRIGGER_USER ?: 'Not available'}
                        Trigger Cause: ${env.JENKINS_TRIGGER_CAUSE ?: 'Not available'}

                        GitHub Pusher: ${env.GITHUB_PUSHER_LOGIN ?: 'Not available'}
                        GitHub User ID: ${env.GITHUB_PUSHER_ID ?: 'Not available'}

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
                        Branch: ${env.BRANCH_NAME ?: env.APP_BRANCH}

                        Trigger Type: ${env.JENKINS_TRIGGER_TYPE ?: 'Not available'}
                        Jenkins User: ${env.JENKINS_TRIGGER_USER ?: 'Not available'}
                        Trigger Cause: ${env.JENKINS_TRIGGER_CAUSE ?: 'Not available'}

                        GitHub Pusher: ${env.GITHUB_PUSHER_LOGIN ?: 'Not available'}
                        GitHub User ID: ${env.GITHUB_PUSHER_ID ?: 'Not available'}
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
