def call() {

    echo 'Initializing pipeline context...'

    // Capture build timestamp
    env.BUILD_TIMESTAMP = sh(
        script: 'date -u +%Y-%m-%dT%H:%M:%SZ',
        returnStdout: true
    ).trim()

    // Extract application version from pom.xml
    env.BUILD_VERSION = sh(
        script: """
            mvn -B -ntp -f "${env.POM_PATH}" \
            help:evaluate \
            -Dexpression=project.version \
            -q -DforceStdout
        """,
        returnStdout: true
    ).trim()

    // Validate application version
    if (!env.BUILD_VERSION) {
        error 'Unable to determine application version from pom.xml'
    }

    // Validate Git commit
    if (!env.GIT_SHORT_COMMIT) {
        error 'Git short commit SHA is missing'
    }

    // Generate image tag: version + short commit SHA
    env.IMAGE_TAG = "${env.BUILD_VERSION}-${env.GIT_SHORT_COMMIT}"

    echo """
    Pipeline context initialized.

    Service          : ${env.SERVICE_NAME}
    Application Ver  : ${env.BUILD_VERSION}
    Commit           : ${env.GIT_SHORT_COMMIT}
    Image Tag        : ${env.IMAGE_TAG}
    Build Timestamp  : ${env.BUILD_TIMESTAMP}
    """
}
