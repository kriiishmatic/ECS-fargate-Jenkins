def call() {

    withAWS(
        credentials: env.AWS_CREDENTIAL_ID,
        region: env.AWS_REGION
    ) {

        script {

            def accountId = sh(
                script: '''
                    aws sts get-caller-identity \
                    --query Account --output text
                ''',
                returnStdout: true
            ).trim()

            if (accountId != '392401698561') {
                error "Unexpected AWS account: ${accountId}"
            }

            def registry =
                '392401698561.dkr.ecr.us-east-1.amazonaws.com'

            env.ECR_IMAGE_URI =
                "${registry}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG}"

            // Verify existing repository
            sh '''
                aws ecr describe-repositories \
                  --repository-names project-k/shipping \
                  --region us-east-1
            '''

            // Authenticate to ECR
            sh """
                aws ecr get-login-password \
                  --region us-east-1 |
                docker login \
                  --username AWS \
                  --password-stdin ${registry}
            """

            // Tag and push
            sh """
                docker tag ${env.SERVICE_NAME}:${env.IMAGE_TAG} \
                  ${env.ECR_IMAGE_URI}

                docker push ${env.ECR_IMAGE_URI}
            """

            echo "Image pushed: ${env.ECR_IMAGE_URI}"
        }
    }
}