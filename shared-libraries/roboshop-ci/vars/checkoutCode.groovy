def call() {

    echo 'Checking out application source code...'

    checkout scm

    env.GIT_COMMIT_ID = sh(
        script: 'git rev-parse HEAD',
        returnStdout: true
    ).trim()

    env.GIT_SHORT_COMMIT = sh(
        script: 'git rev-parse --short=7 HEAD',
        returnStdout: true
    ).trim()

    env.GIT_AUTHOR_NAME = sh(
        script: "git log -1 --format='%an'",
        returnStdout: true
    ).trim()

    env.GIT_AUTHOR_EMAIL = sh(
        script: "git log -1 --format='%ae'",
        returnStdout: true
    ).trim()

    env.GIT_BRANCH_NAME = env.BRANCH_NAME ?: sh(
        script: 'git branch --show-current',
        returnStdout: true
    ).trim()

    echo """
    Checkout completed.

    Service       : ${env.SERVICE_NAME}
    Branch        : ${env.GIT_BRANCH_NAME}
    Commit        : ${env.GIT_COMMIT_ID}
    Author        : ${env.GIT_AUTHOR_NAME}
    Author Email  : ${env.GIT_AUTHOR_EMAIL}
    """
}