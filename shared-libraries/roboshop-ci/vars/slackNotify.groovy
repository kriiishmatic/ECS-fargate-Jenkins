
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
            color: '#3498DB',
            emoji: ':rocket:',
            title: 'CI pipeline started',
            subtitle: 'Build execution is now in progress.'
        ],

        'CI SUCCESS': [
            color: '#2ECC71',
            emoji: ':white_check_mark:',
            title: 'CI pipeline completed successfully',
            subtitle: 'All configured stages passed.'
        ],

        'CI FAILED': [
            color: '#E74C3C',
            emoji: ':rotating_light:',
            title: 'CI pipeline failed',
            subtitle: 'Immediate attention may be required.'
        ],

        'CI ABORTED': [
            color: '#95A5A6',
            emoji: ':warning:',
            title: 'CI pipeline aborted',
            subtitle: 'Build execution was interrupted.'
        ],

        'RELEASE STARTED': [
            color: '#3498DB',
            emoji: ':rocket:',
            title: 'Release started',
            subtitle: 'Deployment process is in progress.'
        ],

        'RELEASE SUCCESS': [
            color: '#2ECC71',
            emoji: ':tada:',
            title: 'Release completed successfully',
            subtitle: 'Application release completed.'
        ],

        'RELEASE FAILED': [
            color: '#E74C3C',
            emoji: ':fire:',
            title: 'Release failed',
            subtitle: 'Deployment requires investigation.'
        ],

        'RELEASE ABORTED': [
            color: '#95A5A6',
            emoji: ':warning:',
            title: 'Release aborted',
            subtitle: 'Release execution was interrupted.'
        ]
    ]

    def style = statusConfig[status] ?: [
        color: '#808080',
        emoji: ':information_source:',
        title: status,
        subtitle: 'Pipeline notification.'
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
    // 3. Identify trigger and triggering user
    // --------------------------------------------------

    def triggerType = env.JENKINS_TRIGGER_TYPE ?: 'Automated Trigger'
    def triggeredBy = ''
    def userId = ''
    def triggerSource = ''

    def githubPusher = env.GITHUB_PUSHER_LOGIN ?: ''
    def githubPusherId = env.GITHUB_PUSHER_ID ?: ''

    def causes = []

    try {
        causes = currentBuild.getBuildCauses() ?: []
    } catch (err) {
        echo "WARNING: Could not retrieve Jenkins build causes: ${err.getMessage()}"
    }

    def userCause = causes.find {
        (it['_class'] ?: '').contains('UserIdCause')
    }

    def causeDescription = causes
        .collect { it['shortDescription'] }
        .findAll { it }
        .join('; ')

    def causeClass = causes
        .collect { it['_class'] ?: '' }
        .join(' ')

    // GitHub push takes priority when verified pusher metadata exists.

    if (githubPusher) {

        triggerType = 'GitHub Push'
        triggeredBy = githubPusher
        userId = githubPusherId
        triggerSource = 'GitHub Webhook'

    } else if (userCause) {

        triggerType = 'Manual'
        triggeredBy = userCause['userName'] ?:
                      userCause['userId'] ?:
                      'Jenkins User'

        userId = userCause['userId'] ?: ''
        triggerSource = 'Jenkins UI'

    } else {

        // Handle automated triggers.

        if (causeClass.contains('BranchEventCause') ||
            causeClass.contains('SCMTriggerCause')) {

            triggerType = 'SCM Trigger'
            triggerSource = 'GitHub / SCM Webhook'

        } else if (causeClass.contains('TimerTriggerCause')) {

            triggerType = 'Scheduled'
            triggerSource = 'Jenkins Scheduler'

        } else if (causeClass.contains('UpstreamCause')) {

            triggerType = 'Upstream Pipeline'
            triggerSource = 'Another Jenkins Pipeline'

        } else {

            triggerType = triggerType ?: 'Automated'
            triggerSource = causeDescription ?: 'Automated Trigger'
        }

        triggeredBy = 'Automated process'
    }

    echo """
    Slack notification identity:

    Trigger Type : ${triggerType}
    Triggered By : ${triggeredBy}
    User ID      : ${userId ?: 'Not applicable'}
    Source       : ${triggerSource}
    """

    // --------------------------------------------------
    // 4. Remove duplicate metadata from message body
    // --------------------------------------------------

    // These details are displayed separately in Slack fields.

    def duplicateMetadataPattern =
        /(?i)^(service|version|branch|commit|trigger type|jenkins user|trigger cause|github pusher|github user id):.*/

    def displayMessage = message.readLines()
        .findAll { line ->
            !(line.trim() ==~ duplicateMetadataPattern)
        }
        .join('\n')
        .trim()

    if (!displayMessage) {
        displayMessage = style.subtitle
    }

    // --------------------------------------------------
    // 5. Build Slack fields
    // --------------------------------------------------

    def fields = [

        [
            type: 'mrkdwn',
            text: ":file_folder: *PROJECT*\n${project}"
        ],

        [
            type: 'mrkdwn',
            text: ":package: *SERVICE*\n${service}"
        ],

        [
            type: 'mrkdwn',
            text: ":number_sign: *BUILD*\n#${buildNumber}"
        ],

        [
            type: 'mrkdwn',
            text: ":label: *VERSION*\n${version}"
        ],

        [
            type: 'mrkdwn',
            text: ":deciduous_tree: *BRANCH*\n`${branch}`"
        ],

        [
            type: 'mrkdwn',
            text: ":bookmark_tabs: *COMMIT*\n`${commit}`"
        ],

        [
            type: 'mrkdwn',
            text: ":zap: *TRIGGER TYPE*\n${triggerType}"
        ],

        [
            type: 'mrkdwn',
            text: ":bust_in_silhouette: *TRIGGERED BY*\n${triggeredBy}"
        ],

        [
            type: 'mrkdwn',
            text: ":satellite: *TRIGGER SOURCE*\n${triggerSource}"
        ]
    ]

    // Display the relevant user ID only when available.

    if (userId) {

        def userIdLabel = githubPusher ?
            'GITHUB USER ID' :
            'JENKINS USER ID'

        fields.add([
            type: 'mrkdwn',
            text: ":id: *${userIdLabel}*\n`${userId}`"
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
                text: "${style.emoji} ${service.toUpperCase()} | ${status}",
                emoji: true
            ]
        ],

        [
            type: 'section',
            text: [
                type: 'mrkdwn',
                text: "*${style.title}*\n${style.subtitle}\n\n${displayMessage}"
            ]
        ],

        [
            type: 'divider'
        ],

        [
            type: 'section',
            text: [
                type: 'mrkdwn',
                text: ":clipboard: *BUILD INFORMATION*"
            ]
        ]
    ]

    // Slack allows a maximum of 10 fields per section block.

    fields.collate(10).each { fieldGroup ->

        blocks.add([
            type: 'section',
            fields: fieldGroup
        ])
    }

    blocks.add([
        type: 'divider'
    ])

    // --------------------------------------------------
    // 7. Jenkins build context
    // --------------------------------------------------

    blocks.add([
        type: 'context',
        elements: [
            [
                type: 'mrkdwn',
                text: ":gear: *Jenkins:* ${jobName}  |  :bar_chart: *Build:* #${buildNumber}"
            ]
        ]
    ])

    // --------------------------------------------------
    // 8. Jenkins build button
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
    // 9. Construct Slack payload
    // --------------------------------------------------

    def payload = [

        text: "${style.emoji} ${status} - ${service} - Build #${buildNumber}",

        attachments: [

            [
                color: style.color,
                blocks: blocks
            ]
        ]
    ]

    def jsonPayload = JsonOutput.toJson(payload)

    // --------------------------------------------------
    // 10. Send Slack notification securely
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

        def httpStatus = response
            .substring(markerIndex + statusMarker.length())
            .trim()

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
