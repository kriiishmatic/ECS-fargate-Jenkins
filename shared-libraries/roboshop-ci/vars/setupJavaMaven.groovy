def call() {

    echo 'Validating Java and Maven installations...'

    sh '''
        set -eu

        echo "Java version:"
        java -version

        echo "Maven version:"
        mvn -version

        echo "Checking Java compiler:"
        javac -version
    '''

    echo 'Java and Maven validation completed.'
}