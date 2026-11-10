
import groovy.json.JsonOutput

def call(Map config = [:]) {

    def status = config.status ?: 'INFO'
    def message = config.message ?: ''

    def jobName = env.JOB_NAME ?: 'Jenkins Job'
    def buildNumber = env.BUILD_NUMBER ?: 'N/A'
    def branch = env.BRANCH_NAME ?: env.GIT_BRANCH ?: 'N/A'
    def commit = env.GIT_SHORT_COMMIT ?: env.GIT_COMMIT ?: 'N/A'
    def buildUrl = env.BUILD_URL ?: ''

    def slackMessage = """
*${status} | ${jobName}*

*Build:* #${buildNumber}
*Branch:* ${branch}
*Commit:* ${commit}

${message}

${buildUrl ? "<${buildUrl}|Open Jenkins Build>" : ''}
"""

    def payload = JsonOutput.toJson([
        text: slackMessage
    ])

    withCredentials([
        string(
            credentialsId: 'slack-jenkins-webhook',
            variable: 'SLACK_WEBHOOK'
        )
    ]) {

        writeFile(
            file: 'slack-payload.json',
            text: payload
        )

        sh '''
            set +x

            curl --fail --silent --show-error \
                --header "Content-Type: application/json" \
                --data-binary @slack-payload.json \
                "$SLACK_WEBHOOK"
        '''
    }
}
