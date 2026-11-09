def call() {

    echo 'Initializing CI pipeline context...'

    env.BUILD_TIMESTAMP = sh(
        script: 'date -u +%Y-%m-%dT%H:%M:%SZ',
        returnStdout: true
    ).trim()

    env.BUILD_VERSION = sh(
        script: """
            mvn -B -ntp -f "${env.POM_PATH}" \
            help:evaluate \
            -Dexpression=project.version \
            -q -DforceStdout
        """,
        returnStdout: true
    ).trim()

    env.IMAGE_TAG = "${env.BUILD_VERSION}-${env.BUILD_NUMBER}-${env.GIT_SHORT_COMMIT}"

    echo """
    Pipeline context initialized.

    Service          : ${env.SERVICE_NAME}
    Build Number     : ${env.BUILD_NUMBER}
    Application Ver  : ${env.BUILD_VERSION}
    Image Tag        : ${env.IMAGE_TAG}
    Build Timestamp  : ${env.BUILD_TIMESTAMP}
    """
}