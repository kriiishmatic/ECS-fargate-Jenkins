def call() {

    echo 'Starting Maven clean and compile...'

    sh """
        set -eu

        mvn -B -ntp -f "${env.POM_PATH}" clean compile
    """

    echo 'Maven clean and compile completed successfully.'
}