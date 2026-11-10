
import groovy.json.JsonOutput

def call(Map config = [:]) {

    def status = (config.status ?: 'INFO').toString().toUpperCase()

    def message = (config.message ?: 'No additional details provided.')
        .toString()
        .stripIndent()
        .trim()

    // --------------------------------------------------
    // 1. Status configuration
    // --------------------------------------------------

    def statusConfig = [
        'CI STARTED': [
            color: '#36A3F7',
            emoji: ':rocket:',
            title: 'Build started'
        ],
        'CI SUCCESS': [
            color: '#2EB67D',
            emoji: ':white_check_mark:',
            title: 'Build completed successfully'
        ],
        'CI FAILED': [
            color: '#E01E5A',
            emoji: ':x:',
            title: 'Build failed'
        ],
        'CI ABORTED': [
            color: '#808080',
            emoji: ':warning:',
            title: 'Build aborted'
        ],
        'RELEASE STARTED': [
            color: '#36A3F7',
            emoji: ':rocket:',
            title: 'Release started'
        ],
        'RELEASE SUCCESS': [
            color: '#2EB67D',
            emoji: ':white_check_mark:',
            title: 'Release completed successfully'
        ],
        'RELEASE FAILED': [
            color: '#E01E5A',
            emoji: ':x:',
            title: 'Release failed'
        ],
        'RELEASE ABORTED': [
            color: '#808080',
            emoji: ':warning:',
            title: 'Release aborted'
        ]
    ]

    def style = statusConfig[status] ?: [
        color: '#808080',
        emoji: ':information_source:',
        title: status
    ]

    // --------------------------------------------------
    // 2. Jenkins build metadata
    // --------------------------------------------------

    def jobName = env.JOB_NAME ?: 'Jenkins Job'
    def buildNumber = env.BUILD_NUMBER ?: 'N/A'
    def branch = env.BRANCH_NAME ?: env.APP_BRANCH ?: 'N/A'
    def commit = env.GIT_SHORT_COMMIT ?: env.GIT_COMMIT ?: 'N/A'
    def service = env.SERVICE_NAME ?: 'N/A'
    def project = env.PROJECT ?: 'N/A'
    def version = env.BUILD_VERSION ?: 'N/A'
    def buildUrl = env.BUILD_URL ?: ''

    commit = commit.take(8)

    // --------------------------------------------------
    // 3. Identify who triggered the Jenkins pipeline
    // --------------------------------------------------

    def triggerName = 'Automated Trigger'
    def triggerId = 'N/A'
    def triggerSource = 'Unknown'

    try {

        def causes = currentBuild.getBuildCauses()

        if (causes && !causes.isEmpty()) {

            def userCause = causes.find {
                it._class?.contains('UserIdCause')
            }

            if (userCause) {

                triggerName = userCause.userName ?: 'Jenkins User'
                triggerId = userCause.userId ?: 'N/A'
                triggerSource = 'Manual / Jenkins UI'

            } else {

                def cause = causes[0]
                def causeClass = cause._class ?: ''

                triggerName = cause.shortDescription ?: 'Automated Trigger'

                if (causeClass.contains('BranchEventCause') ||
                    causeClass.contains('SCMTriggerCause')) {

                    triggerSource = 'SCM / GitHub Webhook'

                } else if (causeClass.contains('TimerTriggerCause')) {

                    triggerSource = 'Scheduled Trigger'

                } else if (causeClass.contains('UpstreamCause')) {

                    triggerSource = 'Upstream Pipeline'

                } else {

                    triggerSource = 'Automated Trigger'
                }
            }
        }

    } catch (err) {

        echo "WARNING: Could not identify pipeline trigger: ${err.getMessage()}"
    }

    // --------------------------------------------------
    // 4. GitHub pusher metadata
    // --------------------------------------------------

    def githubPusher = env.GITHUB_PUSHER_LOGIN ?: ''
    def githubPusherId = env.GITHUB_PUSHER_ID ?: ''

    // --------------------------------------------------
    // 5. Build Slack fields
    // --------------------------------------------------

    def fields = [

        [
            type: 'mrkdwn',
            text: "*PROJECT*\n${project}"
        ],

        [
            type: 'mrkdwn',
            text: "*SERVICE*\n${service}"
        ],

        [
            type: 'mrkdwn',
            text: "*BUILD*\n#${buildNumber}"
        ],

        [
            type: 'mrkdwn',
            text: "*VERSION*\n${version}"
        ],

        [
            type: 'mrkdwn',
            text: "*BRANCH*\n`${branch}`"
        ],

        [
            type: 'mrkdwn',
            text: "*COMMIT*\n`${commit}`"
        ],

        [
            type: 'mrkdwn',
            text: "*TRIGGERED BY*\n${triggerName}"
        ],

        [
            type: 'mrkdwn',
            text: "*USER ID*\n`${triggerId}`"
        ],

        [
            type: 'mrkdwn',
            text: "*TRIGGER SOURCE*\n${triggerSource}"
        ]
    ]

    // Add GitHub pusher details when metadata is available.

    if (githubPusher && githubPusherId) {

        fields.add([
            type: 'mrkdwn',
            text: "*GITHUB PUSHER*\n${githubPusher}"
        ])

        fields.add([
            type: 'mrkdwn',
            text: "*GITHUB USER ID*\n`${githubPusherId}`"
        ])
    }

    // --------------------------------------------------
    // 6. Construct Slack blocks
    // --------------------------------------------------

    def blocks = [

        [
            type: 'header',
            text: [
                type: 'plain_text',
                text: "${style.emoji} ${service.toUpperCase()} - ${status}",
                emoji: true
            ]
        ],

        [
            type: 'section',
            text: [
                type: 'mrkdwn',
                text: "*${style.title}*\n${message}"
            ]
        ],

        [
            type: 'divider'
        ]
    ]

    // IMPORTANT:
    // Slack allows a maximum of 10 fields per section block.
    // Split the fields into groups of 10.

    fields.collate(10).each { fieldGroup ->

        blocks.add([
            type: 'section',
            fields: fieldGroup
        ])
    }

    blocks.add([
        type: 'divider'
    ])

    blocks.add([
        type: 'context',
        elements: [
            [
                type: 'mrkdwn',
                text: "*Jenkins Job:* ${jobName}  |  *Build:* #${buildNumber}"
            ]
        ]
    ])

    // --------------------------------------------------
    // 7. Add clickable Jenkins build button
    // --------------------------------------------------

    if (buildUrl) {

        blocks.add([

            type: 'actions',

            elements: [

                [
                    type: 'button',

                    text: [
                        type: 'plain_text',
                        text: 'View Jenkins Build',
                        emoji: true
                    ],

                    url: buildUrl,

                    style: (
                        status == 'CI FAILED' ||
                        status == 'RELEASE FAILED'
                    ) ? 'danger' : 'primary'
                ]
            ]
        ])
    }

    // --------------------------------------------------
    // 8. Construct Slack payload
    // --------------------------------------------------

    def payload = [

        text: "${status} - ${service} - Build #${buildNumber}",

        attachments: [

            [
                color: style.color,
                blocks: blocks
            ]
        ]
    ]

    def jsonPayload = JsonOutput.toJson(payload)

    // --------------------------------------------------
    // 9. Send Slack notification securely
    // --------------------------------------------------

    withCredentials([

        string(
            credentialsId: 'slack-jenkins-webhook',
            variable: 'SLACK_WEBHOOK'
        )

    ]) {

        writeFile(
            file: 'slack-payload.json',
            text: jsonPayload
        )

        def response = sh(

            script: '''
                set +x

                curl --silent --show-error \
                    --write-out '\\nHTTP_STATUS:%{http_code}' \
                    --header "Content-Type: application/json" \
                    --data-binary @slack-payload.json \
                    "$SLACK_WEBHOOK"
            ''',

            returnStdout: true

        ).trim()

        def statusMarker = 'HTTP_STATUS:'
        def markerIndex = response.lastIndexOf(statusMarker)

        if (markerIndex < 0) {
            error "Slack notification failed. No HTTP status received. Response: ${response}"
        }

        def responseBody = response.substring(0, markerIndex).trim()
        def httpStatus = response.substring(markerIndex + statusMarker.length()).trim()

        if (httpStatus != '200' || responseBody != 'ok') {

            error """
            Slack notification failed.

            HTTP Status : ${httpStatus}
            Response    : ${responseBody}
            """
        }

        echo "Slack notification sent successfully: ${status}"
    }
}
