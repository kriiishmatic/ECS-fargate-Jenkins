
def call(Map config = [:]) {

    def status = config.status ?: 'INFO'
    def message = config.message ?: ''

    try {

        slackNotify(
            status: status,
            message: message
        )

    } catch (err) {

        echo """
        WARNING: Slack notification could not be delivered.

        Status : ${status}
        Error  : ${err.getMessage()}
        """
    }
}
