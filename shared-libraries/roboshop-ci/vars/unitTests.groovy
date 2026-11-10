def call() {

    echo 'Executing Maven unit tests...'

    sh 'mvn -B test'

    echo 'Maven unit tests completed successfully.'
}
