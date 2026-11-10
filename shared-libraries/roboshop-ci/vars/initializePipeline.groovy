
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

    if (!env.BUILD_VERSION) {
        error 'Unable to determine application version from pom.xml'
    }

    
def call() {

    echo 'Initializing pipeline context...'

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

    if (!env.BUILD_VERSION) {
        error 'Unable to determine application version from pom.xml'
    }

    if (!env.GIT_SHORT_COMMIT) {
        error 'Git commit SHA is missing'
    }

    env.IMAGE_TAG = "${env.BUILD_VERSION}-${env.GIT_SHORT_COMMIT}"

    echo """
    Pipeline context initialized.

    Service          : ${env.SERVICE_NAME}
    Build Number     : ${env.BUILD_NUMBER}
    Application Ver  : ${env.BUILD_VERSION}
    Commit           : ${env.GIT_SHORT_COMMIT}
    Image Tag        : ${env.IMAGE_TAG}
    Build Timestamp  : ${env.BUILD_TIMESTAMP}
    """
}


    echo """
    Pipeline context initialized.

    Service          : ${env.SERVICE_NAME}
    Build Number     : ${env.BUILD_NUMBER}
    Application Ver  : ${env.BUILD_VERSION}
    Commit           : ${env.GIT_SHORT_COMMIT}
    Image Tag        : ${env.IMAGE_TAG}
    Build Timestamp  : ${env.BUILD_TIMESTAMP}
    """
}
