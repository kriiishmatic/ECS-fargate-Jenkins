def call() {

    withAWS(
        credentials: env.AWS_CREDENTIAL_ID,
        region: env.AWS_REGION
    ) {

        script {

            def accountId = sh(
                script: '''
                    aws sts get-caller-identity \
                    --query Account \
                    --output text
                ''',
                returnStdout: true
            ).trim()

            def registry =
                "${accountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"

            env.ECR_REGISTRY = registry
            env.ECR_IMAGE_URI =
                "${registry}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG}"

            echo "AWS Account: ${accountId}"
            echo "AWS Region: ${env.AWS_REGION}"
            echo "ECR Image: ${env.ECR_IMAGE_URI}"

            // Verify the existing repository; do not create a new one.
            sh """
                aws ecr describe-repositories \
                  --repository-names "${env.ECR_REPOSITORY}" \
                  --region "${env.AWS_REGION}"
            """

            sh """
                aws ecr get-login-password \
                  --region "${env.AWS_REGION}" |
                docker login \
                  --username AWS \
                  --password-stdin ${registry}
            """

            sh """
                docker tag ${env.SERVICE_NAME}:${env.IMAGE_TAG} \
                  ${env.ECR_IMAGE_URI}

                docker push ${env.ECR_IMAGE_URI}
            """

            env.ECR_IMAGE_DIGEST = sh(
                script: """
                    aws ecr describe-images \
                      --repository-name "${env.ECR_REPOSITORY}" \
                      --image-ids imageTag="${env.IMAGE_TAG}" \
                      --query 'imageDetails[0].imageDigest' \
                      --output text
                """,
                returnStdout: true
            ).trim()
        }
    }
}